codeunit 50113 "PTE IBKR Import Provider" implements "PTE Broker Report Provider"
{
    procedure Import(Broker: Record "PTE Broker"; SourceFileName: Text; var SourceInStream: InStream; var ImportHeader: Record "PTE Broker Import Header")
    var
        BrokerImportManagement: Codeunit "PTE Broker Import Management";
        CsvFields: List of [Text];
        LineText: Text;
        SourceLineNo: Integer;
        TransactionHeaderFound: Boolean;
        TransactionLineCount: Integer;
        AmountCurrencyCode: Code[10];
    begin
        BrokerImportManagement.CreateImportHeader(Broker, SourceFileName, ImportHeader);

        while not SourceInStream.EOS do begin
            SourceInStream.ReadText(LineText);
            SourceLineNo += 1;
            ParseCsvLine(LineText, CsvFields);

            if IsStatementData(CsvFields, 'Title') then
                ImportHeader."Report Title" := CopyStr(GetField(CsvFields, 4), 1, MaxStrLen(ImportHeader."Report Title"));
            if IsStatementData(CsvFields, 'Period') then
                ImportHeader."Report Period" := CopyStr(GetField(CsvFields, 4), 1, MaxStrLen(ImportHeader."Report Period"));
            if IsSummaryData(CsvFields, 'Base Currency') then
                ImportHeader."Base Currency Code" := CopyStr(UpperCase(GetField(CsvFields, 4)), 1, MaxStrLen(ImportHeader."Base Currency Code"));

            if IsTransactionHistoryHeader(CsvFields) then begin
                if not IsExpectedTransactionHeader(CsvFields) then begin
                    SetHeaderFailed(ImportHeader, InvalidSchemaErr);
                    exit;
                end;

                TransactionHeaderFound := true;
            end;

            if IsTransactionHistoryData(CsvFields) then begin
                if not TransactionHeaderFound then begin
                    SetHeaderFailed(ImportHeader, MissingTransactionHeaderErr);
                    exit;
                end;

                AmountCurrencyCode := ImportHeader."Base Currency Code";
                if AmountCurrencyCode = '' then
                    AmountCurrencyCode := Broker."Base Currency Code";

                InsertTransactionLine(ImportHeader, Broker, CsvFields, LineText, SourceLineNo, AmountCurrencyCode);
                TransactionLineCount += 1;
            end;
        end;

        if not TransactionHeaderFound then begin
            SetHeaderFailed(ImportHeader, MissingTransactionHeaderErr);
            exit;
        end;

        if TransactionLineCount = 0 then begin
            SetHeaderFailed(ImportHeader, MissingTransactionLinesErr);
            exit;
        end;

        if ImportHeader."Base Currency Code" = '' then
            ImportHeader."Base Currency Code" := Broker."Base Currency Code";
        if ImportHeader."Base Currency Code" = '' then
            ImportHeader."Schema Message" := CopyStr(MissingBaseCurrencyWarningTxt, 1, MaxStrLen(ImportHeader."Schema Message"));

        if (Broker."Base Currency Code" <> '') and (ImportHeader."Base Currency Code" <> '') and (Broker."Base Currency Code" <> ImportHeader."Base Currency Code") then begin
            SetHeaderFailed(ImportHeader, BaseCurrencyMismatchErr);
            exit;
        end;

        ImportHeader.Modify();
    end;

    local procedure InsertTransactionLine(ImportHeader: Record "PTE Broker Import Header"; Broker: Record "PTE Broker"; CsvFields: List of [Text]; RawData: Text; SourceLineNo: Integer; AmountCurrencyCode: Code[10])
    var
        ImportLine: Record "PTE Broker Import Line";
        TradeDate: Date;
        Quantity: Decimal;
        Price: Decimal;
        GrossAmount: Decimal;
        CommissionAmount: Decimal;
        NetAmount: Decimal;
        ParseError: Text;
    begin
        ImportLine.Init();
        ImportLine."Import Entry No." := ImportHeader."Entry No.";
        ImportLine."Line No." := SourceLineNo * 10000;
        ImportLine.Selected := true;
        ImportLine.Status := ImportLine.Status::New;
        ImportLine."Broker Code" := Broker.Code;
        ImportLine."Broker Account No." := CopyStr(CleanValue(GetField(CsvFields, 4)), 1, MaxStrLen(ImportLine."Broker Account No."));
        ImportLine.Description := CopyStr(CleanValue(GetField(CsvFields, 5)), 1, MaxStrLen(ImportLine.Description));
        ImportLine."Source Transaction Type" := CopyStr(CleanValue(GetField(CsvFields, 6)), 1, MaxStrLen(ImportLine."Source Transaction Type"));
        ImportLine."Transaction Type" := MapTransactionType(ImportLine."Source Transaction Type");
        ImportLine."Instrument Type" := MapInstrumentType(ImportLine."Transaction Type", CleanValue(GetField(CsvFields, 7)));
        ImportLine.Ticker := CopyStr(CleanValue(GetField(CsvFields, 7)), 1, MaxStrLen(ImportLine.Ticker));
        ImportLine."Price Currency Code" := CopyStr(UpperCase(CleanValue(GetField(CsvFields, 10))), 1, MaxStrLen(ImportLine."Price Currency Code"));
        ImportLine."Currency Code" := AmountCurrencyCode;
        ImportLine."Source File Name" := ImportHeader."Source File Name";
        ImportLine."Source Line No." := SourceLineNo;
        ImportLine."Raw Data" := CopyStr(RawData, 1, MaxStrLen(ImportLine."Raw Data"));

        if not TryParseDate(GetField(CsvFields, 3), TradeDate) then
            ParseError := AppendError(ParseError, InvalidTradeDateErr)
        else begin
            ImportLine."Trade Date" := TradeDate;
            ImportLine."Tax Year" := Date2DMY(TradeDate, 3);
        end;

        if not TryParseDecimal(GetField(CsvFields, 8), Quantity) then
            ParseError := AppendError(ParseError, InvalidQuantityErr)
        else
            ImportLine.Quantity := Quantity;

        if not TryParseDecimal(GetField(CsvFields, 9), Price) then
            ParseError := AppendError(ParseError, InvalidPriceErr)
        else
            ImportLine.Price := Price;

        if not TryParseDecimal(GetField(CsvFields, 11), GrossAmount) then
            ParseError := AppendError(ParseError, InvalidGrossAmountErr)
        else
            ImportLine."Gross Amount" := GrossAmount;

        if not TryParseDecimal(GetField(CsvFields, 12), CommissionAmount) then
            ParseError := AppendError(ParseError, InvalidCommissionErr)
        else
            ImportLine."Fee Amount" := CommissionAmount;

        if not TryParseDecimal(GetField(CsvFields, 13), NetAmount) then
            ParseError := AppendError(ParseError, InvalidNetAmountErr)
        else
            ImportLine."Net Amount" := NetAmount;

        ImportLine."Duplicate Check Key" := BuildDuplicateCheckKey(ImportLine);
        ImportLine."External Entry ID" := CopyStr(ImportLine."Duplicate Check Key", 1, MaxStrLen(ImportLine."External Entry ID"));

        if ParseError <> '' then begin
            ImportLine.Status := ImportLine.Status::Error;
            ImportLine."Provider Error" := true;
            ImportLine."Validation Message" := CopyStr(ParseError, 1, MaxStrLen(ImportLine."Validation Message"));
        end;

        ImportLine.Insert();
    end;

    local procedure ParseCsvLine(LineText: Text; var CsvFields: List of [Text])
    var
        CurrentField: Text;
        Character: Text[1];
        Position: Integer;
        InQuotes: Boolean;
    begin
        Clear(CsvFields);
        CurrentField := '';
        Position := 1;

        while Position <= StrLen(LineText) do begin
            Character := CopyStr(LineText, Position, 1);
            if Character = '"' then begin
                if InQuotes and (Position < StrLen(LineText)) and (CopyStr(LineText, Position + 1, 1) = '"') then begin
                    CurrentField += '"';
                    Position += 1;
                end else
                    InQuotes := not InQuotes;
            end else
                if (Character = ',') and not InQuotes then begin
                    CsvFields.Add(CurrentField);
                    CurrentField := '';
                end else
                    CurrentField += Character;

            Position += 1;
        end;

        CsvFields.Add(CurrentField);
    end;

    local procedure IsStatementData(CsvFields: List of [Text]; FieldName: Text): Boolean
    begin
        exit((NormalizeField(GetField(CsvFields, 1)) = 'STATEMENT') and (NormalizeField(GetField(CsvFields, 2)) = 'DATA') and (NormalizeField(GetField(CsvFields, 3)) = NormalizeField(FieldName)));
    end;

    local procedure IsSummaryData(CsvFields: List of [Text]; FieldName: Text): Boolean
    begin
        exit((NormalizeField(GetField(CsvFields, 1)) = 'SUMMARY') and (NormalizeField(GetField(CsvFields, 2)) = 'DATA') and (NormalizeField(GetField(CsvFields, 3)) = NormalizeField(FieldName)));
    end;

    local procedure IsTransactionHistoryHeader(CsvFields: List of [Text]): Boolean
    begin
        exit((NormalizeField(GetField(CsvFields, 1)) = 'TRANSACTION HISTORY') and (NormalizeField(GetField(CsvFields, 2)) = 'HEADER'));
    end;

    local procedure IsTransactionHistoryData(CsvFields: List of [Text]): Boolean
    begin
        exit((NormalizeField(GetField(CsvFields, 1)) = 'TRANSACTION HISTORY') and (NormalizeField(GetField(CsvFields, 2)) = 'DATA'));
    end;

    local procedure IsExpectedTransactionHeader(CsvFields: List of [Text]): Boolean
    begin
        if CsvFields.Count() < 13 then
            exit(false);

        exit(
            (NormalizeField(GetField(CsvFields, 3)) = 'DATE') and
            (NormalizeField(GetField(CsvFields, 4)) = 'ACCOUNT') and
            (NormalizeField(GetField(CsvFields, 5)) = 'DESCRIPTION') and
            (NormalizeField(GetField(CsvFields, 6)) = 'TRANSACTION TYPE') and
            (NormalizeField(GetField(CsvFields, 7)) = 'SYMBOL') and
            (NormalizeField(GetField(CsvFields, 8)) = 'QUANTITY') and
            (NormalizeField(GetField(CsvFields, 9)) = 'PRICE') and
            (NormalizeField(GetField(CsvFields, 10)) = 'PRICE CURRENCY') and
            (NormalizeField(GetField(CsvFields, 11)) = 'GROSS AMOUNT') and
            (NormalizeField(GetField(CsvFields, 12)) = 'COMMISSION') and
            (NormalizeField(GetField(CsvFields, 13)) = 'NET AMOUNT'));
    end;

    local procedure GetField(CsvFields: List of [Text]; FieldNo: Integer): Text
    begin
        if CsvFields.Count() < FieldNo then
            exit('');

        exit(CsvFields.Get(FieldNo));
    end;

    local procedure CleanValue(Value: Text): Text
    begin
        Value := DelChr(Value, '<>', ' ');
        if Value = '-' then
            exit('');

        exit(Value);
    end;

    local procedure NormalizeField(Value: Text): Text
    begin
        exit(UpperCase(DelChr(Value, '<>', ' ')));
    end;

    local procedure TryParseDate(Value: Text; var DateValue: Date): Boolean
    begin
        Value := CleanValue(Value);
        if Value = '' then
            exit(false);

        exit(Evaluate(DateValue, Value, 9));
    end;

    local procedure TryParseDecimal(Value: Text; var DecimalValue: Decimal): Boolean
    var
        Mantissa: Decimal;
        Exponent: Integer;
        ExponentText: Text;
        MantissaText: Text;
        EPosition: Integer;
        Index: Integer;
    begin
        Value := CleanValue(Value);
        if Value = '' then begin
            DecimalValue := 0;
            exit(true);
        end;

        if Evaluate(DecimalValue, Value, 9) then
            exit(true);

        EPosition := StrPos(LowerCase(Value), 'e');
        if EPosition = 0 then
            exit(false);

        MantissaText := CopyStr(Value, 1, EPosition - 1);
        ExponentText := CopyStr(Value, EPosition + 1);
        if not Evaluate(Mantissa, MantissaText, 9) then
            exit(false);
        if not Evaluate(Exponent, ExponentText, 9) then
            exit(false);

        DecimalValue := Mantissa;
        if Exponent > 0 then
            for Index := 1 to Exponent do
                DecimalValue *= 10
        else
            for Index := 1 to -Exponent do
                DecimalValue /= 10;

        exit(true);
    end;

    local procedure MapTransactionType(SourceTransactionType: Text): Enum "PTE Broker Transaction Type"
    begin
        case NormalizeField(SourceTransactionType) of
            'BUY':
                exit("PTE Broker Transaction Type"::Buy);
            'SELL':
                exit("PTE Broker Transaction Type"::Sell);
            'DIVIDEND':
                exit("PTE Broker Transaction Type"::Dividend);
            'INTEREST':
                exit("PTE Broker Transaction Type"::Interest);
            'FEE':
                exit("PTE Broker Transaction Type"::Fee);
            'TAX':
                exit("PTE Broker Transaction Type"::Tax);
            'DEPOSIT', 'ELECTRONIC FUND TRANSFER':
                exit("PTE Broker Transaction Type"::Deposit);
            'WITHDRAWAL':
                exit("PTE Broker Transaction Type"::Withdrawal);
        end;

        exit("PTE Broker Transaction Type"::Other);
    end;

    local procedure MapInstrumentType(TransactionType: Enum "PTE Broker Transaction Type"; Symbol: Text): Enum "PTE Instrument Type"
    begin
        if Symbol = '' then
            exit("PTE Instrument Type"::Cash);
        if TransactionType in [TransactionType::Buy, TransactionType::Sell, TransactionType::Dividend] then
            exit("PTE Instrument Type"::Stock);

        exit("PTE Instrument Type"::Other);
    end;

    local procedure BuildDuplicateCheckKey(ImportLine: Record "PTE Broker Import Line"): Text[250]
    var
        DuplicateCheckKey: Text;
    begin
        DuplicateCheckKey := ImportLine."Broker Code" + '|' + Format(ImportLine."Trade Date", 0, 9) + '|' + ImportLine."Broker Account No." + '|' + ImportLine."Source Transaction Type" + '|' + ImportLine.Ticker + '|' + Format(ImportLine.Quantity, 0, 9) + '|' + Format(ImportLine.Price, 0, 9) + '|' + ImportLine."Price Currency Code" + '|' + Format(ImportLine."Gross Amount", 0, 9) + '|' + Format(ImportLine."Fee Amount", 0, 9) + '|' + Format(ImportLine."Net Amount", 0, 9) + '|' + ImportLine.Description;
        exit(CopyStr(DuplicateCheckKey, 1, 250));
    end;

    local procedure AppendError(CurrentError: Text; NewError: Text): Text
    begin
        if CurrentError = '' then
            exit(NewError);

        exit(CurrentError + ' ' + NewError);
    end;

    local procedure SetHeaderFailed(var ImportHeader: Record "PTE Broker Import Header"; MessageText: Text)
    begin
        ImportHeader.Status := ImportHeader.Status::Failed;
        ImportHeader."Schema Message" := CopyStr(MessageText, 1, MaxStrLen(ImportHeader."Schema Message"));
        ImportHeader.Modify();
    end;

    var
        InvalidSchemaErr: Label 'The file does not match the Interactive Brokers Transaction History CSV schema.';
        MissingTransactionHeaderErr: Label 'The Interactive Brokers Transaction History header was not found before transaction data.';
        MissingTransactionLinesErr: Label 'No transaction lines were found in the Interactive Brokers report.';
        MissingBaseCurrencyWarningTxt: Label 'Base currency was not found in the report summary.';
        BaseCurrencyMismatchErr: Label 'The report base currency does not match the broker base currency.';
        InvalidTradeDateErr: Label 'Trade date could not be parsed.';
        InvalidQuantityErr: Label 'Quantity could not be parsed.';
        InvalidPriceErr: Label 'Price could not be parsed.';
        InvalidGrossAmountErr: Label 'Gross amount could not be parsed.';
        InvalidCommissionErr: Label 'Commission could not be parsed.';
        InvalidNetAmountErr: Label 'Net amount could not be parsed.';
}