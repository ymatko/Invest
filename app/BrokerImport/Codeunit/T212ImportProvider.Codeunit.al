codeunit 50115 "PTE T212 Import Provider" implements "PTE Broker Report Provider"
{
    procedure Import(Broker: Record "PTE Broker"; SourceFileName: Text; var SourceInStream: InStream; var ImportHeader: Record "PTE Broker Import Header")
    var
        BrokerImportManagement: Codeunit "PTE Broker Import Management";
        HeaderFields: List of [Text];
        CsvFields: List of [Text];
        LineText: Text;
        SourceLineNo: Integer;
        HeaderFound: Boolean;
        TransactionLineCount: Integer;
    begin
        BrokerImportManagement.CreateImportHeader(Broker, SourceFileName, ImportHeader);
        ImportHeader."Report Title" := 'Trading 212 Transactions';
        ImportHeader."Report Period" := CopyStr(SourceFileName, 1, MaxStrLen(ImportHeader."Report Period"));
        ImportHeader."Base Currency Code" := Broker."Base Currency Code";

        while not SourceInStream.EOS do begin
            SourceInStream.ReadText(LineText);
            SourceLineNo += 1;
            ParseCsvLine(LineText, CsvFields);

            if not HeaderFound then begin
                HeaderFields := CsvFields;
                if not IsExpectedHeader(HeaderFields) then begin
                    SetHeaderFailed(ImportHeader, InvalidSchemaErr);
                    exit;
                end;

                HeaderFound := true;
                continue;
            end;

            InsertTransactionLine(ImportHeader, Broker, HeaderFields, CsvFields, LineText, SourceLineNo);
            TransactionLineCount += 1;
        end;

        if not HeaderFound then begin
            SetHeaderFailed(ImportHeader, MissingHeaderErr);
            exit;
        end;

        if TransactionLineCount = 0 then begin
            SetHeaderFailed(ImportHeader, MissingTransactionLinesErr);
            exit;
        end;

        ImportHeader.Modify();
    end;

    local procedure InsertTransactionLine(ImportHeader: Record "PTE Broker Import Header"; Broker: Record "PTE Broker"; HeaderFields: List of [Text]; CsvFields: List of [Text]; RawData: Text; SourceLineNo: Integer)
    var
        ImportLine: Record "PTE Broker Import Line";
        TradeDate: Date;
        Quantity: Decimal;
        Price: Decimal;
        TotalAmount: Decimal;
        FeeAmount: Decimal;
        TaxAmount: Decimal;
        FileExchangeRate: Decimal;
        ParseError: Text;
        Action: Text;
        TotalCurrencyCode: Code[10];
        FeeCurrencyCode: Code[10];
        TaxCurrencyCode: Code[10];
    begin
        Action := CleanValue(GetFieldByName(HeaderFields, CsvFields, 'Action'));
        TotalCurrencyCode := CopyStr(UpperCase(CleanValue(GetFieldByName(HeaderFields, CsvFields, 'Currency (Total)'))), 1, MaxStrLen(TotalCurrencyCode));
        FeeCurrencyCode := CopyStr(UpperCase(CleanValue(GetFieldByName(HeaderFields, CsvFields, 'Currency (Currency conversion fee)'))), 1, MaxStrLen(FeeCurrencyCode));
        TaxCurrencyCode := CopyStr(UpperCase(CleanValue(GetFieldByName(HeaderFields, CsvFields, 'Currency (Withholding tax)'))), 1, MaxStrLen(TaxCurrencyCode));

        ImportLine.Init();
        ImportLine."Import Entry No." := ImportHeader."Entry No.";
        ImportLine."Line No." := SourceLineNo * 10000;
        ImportLine.Selected := true;
        ImportLine.Status := ImportLine.Status::New;
        ImportLine."Broker Code" := Broker.Code;
        ImportLine."Broker Account No." := Broker."External Account No.";
        ImportLine.ISIN := CopyStr(CleanValue(GetFieldByName(HeaderFields, CsvFields, 'ISIN')), 1, MaxStrLen(ImportLine.ISIN));
        ImportLine.Ticker := CopyStr(UpperCase(CleanValue(GetFieldByName(HeaderFields, CsvFields, 'Ticker'))), 1, MaxStrLen(ImportLine.Ticker));
        ImportLine.Description := CopyStr(GetDescription(HeaderFields, CsvFields), 1, MaxStrLen(ImportLine.Description));
        ImportLine."External Entry ID" := CopyStr(CleanValue(GetFieldByName(HeaderFields, CsvFields, 'ID')), 1, MaxStrLen(ImportLine."External Entry ID"));
        ImportLine."Source Transaction Type" := CopyStr(Action, 1, MaxStrLen(ImportLine."Source Transaction Type"));
        ImportLine."Transaction Type" := MapTransactionType(Action);
        ImportLine."Instrument Type" := MapInstrumentType(Action, ImportLine.Ticker);
        ImportLine."Price Currency Code" := CopyStr(UpperCase(CleanValue(GetFieldByName(HeaderFields, CsvFields, 'Currency (Price / share)'))), 1, MaxStrLen(ImportLine."Price Currency Code"));
        ImportLine."Currency Code" := GetAmountCurrencyCode(TotalCurrencyCode, FeeCurrencyCode, Broker."Base Currency Code");
        ImportLine."Source File Name" := ImportHeader."Source File Name";
        ImportLine."Source Line No." := SourceLineNo;
        ImportLine."Raw Data" := CopyStr(RawData, 1, MaxStrLen(ImportLine."Raw Data"));

        if not TryParseDate(GetFieldByName(HeaderFields, CsvFields, 'Time'), TradeDate) then
            ParseError := AppendError(ParseError, InvalidTradeDateErr)
        else begin
            ImportLine."Trade Date" := TradeDate;
            ImportLine."Tax Year" := Date2DMY(TradeDate, 3);
        end;

        if not TryParseDecimal(GetFieldByName(HeaderFields, CsvFields, 'No. of shares'), Quantity) then
            ParseError := AppendError(ParseError, InvalidQuantityErr)
        else
            ImportLine.Quantity := Quantity;

        if not TryParseDecimal(GetFieldByName(HeaderFields, CsvFields, 'Price / share'), Price) then
            ParseError := AppendError(ParseError, InvalidPriceErr)
        else
            ImportLine.Price := Price;

        if not TryParseDecimal(GetFieldByName(HeaderFields, CsvFields, 'Exchange rate'), FileExchangeRate) then
            FileExchangeRate := 0;

        if not TryParseDecimal(GetFieldByName(HeaderFields, CsvFields, 'Total'), TotalAmount) then
            ParseError := AppendError(ParseError, InvalidTotalErr);

        if not TryParseDecimal(GetFieldByName(HeaderFields, CsvFields, 'Currency conversion fee'), FeeAmount) then
            ParseError := AppendError(ParseError, InvalidFeeErr);

        if not TryParseDecimal(GetFieldByName(HeaderFields, CsvFields, 'Withholding tax'), TaxAmount) then
            ParseError := AppendError(ParseError, InvalidTaxErr);

        ApplyAmounts(ImportLine, Action, TotalAmount, FeeAmount, TaxAmount, FileExchangeRate, TotalCurrencyCode, FeeCurrencyCode, TaxCurrencyCode);
        ImportLine."Duplicate Check Key" := BuildDuplicateCheckKey(ImportLine);
        if ImportLine."External Entry ID" = '' then
            ImportLine."External Entry ID" := CopyStr(ImportLine."Duplicate Check Key", 1, MaxStrLen(ImportLine."External Entry ID"));

        if ParseError <> '' then begin
            ImportLine.Status := ImportLine.Status::Error;
            ImportLine."Provider Error" := true;
            ImportLine."Validation Message" := CopyStr(ParseError, 1, MaxStrLen(ImportLine."Validation Message"));
        end;

        ImportLine.Insert();
    end;

    local procedure ApplyAmounts(var ImportLine: Record "PTE Broker Import Line"; Action: Text; TotalAmount: Decimal; FeeAmount: Decimal; TaxAmount: Decimal; FileExchangeRate: Decimal; TotalCurrencyCode: Code[10]; FeeCurrencyCode: Code[10]; TaxCurrencyCode: Code[10])
    var
        SignedTotalAmount: Decimal;
        SignedFeeAmount: Decimal;
        SignedTaxAmount: Decimal;
    begin
        SignedTotalAmount := GetSignedTotalAmount(Action, TotalAmount);
        SignedFeeAmount := 0;
        if FeeAmount <> 0 then
            SignedFeeAmount := -Abs(FeeAmount);

        SignedTaxAmount := ConvertWithholdingTax(TaxAmount, FileExchangeRate, ImportLine."Currency Code", TaxCurrencyCode);

        case NormalizeField(Action) of
            'MARKET BUY':
                begin
                    ImportLine."Gross Amount" := SignedTotalAmount;
                    ImportLine."Fee Amount" := SignedFeeAmount;
                    ImportLine."Tax Amount" := 0;
                    ImportLine."Net Amount" := SignedTotalAmount + SignedFeeAmount;
                end;
            'MARKET SELL':
                begin
                    ImportLine."Gross Amount" := SignedTotalAmount;
                    ImportLine."Fee Amount" := SignedFeeAmount;
                    ImportLine."Tax Amount" := 0;
                    ImportLine."Net Amount" := SignedTotalAmount + SignedFeeAmount;
                end;
            'CURRENCY CONVERSION':
                begin
                    ImportLine."Gross Amount" := 0;
                    ImportLine."Fee Amount" := SignedFeeAmount;
                    if ImportLine."Fee Amount" = 0 then
                        ImportLine."Fee Amount" := SignedTotalAmount;
                    ImportLine."Net Amount" := ImportLine."Fee Amount";
                end;
            'DIVIDEND (DIVIDEND)':
                begin
                    ImportLine."Gross Amount" := SignedTotalAmount;
                    ImportLine."Tax Amount" := SignedTaxAmount;
                    ImportLine."Net Amount" := SignedTotalAmount;
                end;
            else begin
                ImportLine."Gross Amount" := SignedTotalAmount;
                ImportLine."Fee Amount" := SignedFeeAmount;
                ImportLine."Tax Amount" := SignedTaxAmount;
                ImportLine."Net Amount" := SignedTotalAmount + SignedFeeAmount;
            end;
        end;

        if (TotalCurrencyCode = '') and (FeeCurrencyCode <> '') then
            ImportLine."Currency Code" := FeeCurrencyCode;
    end;

    local procedure ConvertWithholdingTax(TaxAmount: Decimal; FileExchangeRate: Decimal; AmountCurrencyCode: Code[10]; TaxCurrencyCode: Code[10]): Decimal
    begin
        if TaxAmount = 0 then
            exit(0);
        if (TaxCurrencyCode = '') or (TaxCurrencyCode = AmountCurrencyCode) then
            exit(-Abs(TaxAmount));
        if FileExchangeRate <> 0 then
            exit(-Abs(TaxAmount * FileExchangeRate));

        exit(0);
    end;

    local procedure GetSignedTotalAmount(Action: Text; TotalAmount: Decimal): Decimal
    begin
        case NormalizeField(Action) of
            'MARKET BUY', 'WITHDRAWAL':
                exit(-Abs(TotalAmount));
            'MARKET SELL', 'DIVIDEND (DIVIDEND)', 'LENDING INTEREST', 'DEPOSIT':
                exit(Abs(TotalAmount));
        end;

        exit(TotalAmount);
    end;

    local procedure GetAmountCurrencyCode(TotalCurrencyCode: Code[10]; FeeCurrencyCode: Code[10]; BrokerBaseCurrencyCode: Code[10]): Code[10]
    begin
        if TotalCurrencyCode <> '' then
            exit(TotalCurrencyCode);
        if FeeCurrencyCode <> '' then
            exit(FeeCurrencyCode);

        exit(BrokerBaseCurrencyCode);
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

    local procedure IsExpectedHeader(HeaderFields: List of [Text]): Boolean
    begin
        exit(
            HasHeader(HeaderFields, 'Action') and
            HasHeader(HeaderFields, 'Time') and
            HasHeader(HeaderFields, 'ID') and
            HasHeader(HeaderFields, 'No. of shares') and
            HasHeader(HeaderFields, 'Price / share') and
            HasHeader(HeaderFields, 'Currency (Price / share)') and
            HasHeader(HeaderFields, 'Total') and
            HasHeader(HeaderFields, 'Currency (Total)'));
    end;

    local procedure HasHeader(HeaderFields: List of [Text]; HeaderName: Text): Boolean
    begin
        exit(GetHeaderIndex(HeaderFields, HeaderName) <> 0);
    end;

    local procedure GetFieldByName(HeaderFields: List of [Text]; CsvFields: List of [Text]; HeaderName: Text): Text
    var
        FieldNo: Integer;
    begin
        FieldNo := GetHeaderIndex(HeaderFields, HeaderName);
        if FieldNo = 0 then
            exit('');

        exit(GetField(CsvFields, FieldNo));
    end;

    local procedure GetHeaderIndex(HeaderFields: List of [Text]; HeaderName: Text): Integer
    var
        Index: Integer;
    begin
        for Index := 1 to HeaderFields.Count() do
            if NormalizeField(HeaderFields.Get(Index)) = NormalizeField(HeaderName) then
                exit(Index);

        exit(0);
    end;

    local procedure GetField(CsvFields: List of [Text]; FieldNo: Integer): Text
    begin
        if CsvFields.Count() < FieldNo then
            exit('');

        exit(CsvFields.Get(FieldNo));
    end;

    local procedure GetDescription(HeaderFields: List of [Text]; CsvFields: List of [Text]): Text
    var
        Name: Text;
        Notes: Text;
    begin
        Name := CleanValue(GetFieldByName(HeaderFields, CsvFields, 'Name'));
        Notes := CleanValue(GetFieldByName(HeaderFields, CsvFields, 'Notes'));
        if Name <> '' then
            exit(Name);

        exit(Notes);
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
        if StrLen(Value) >= 10 then
            Value := CopyStr(Value, 1, 10);
        if Value = '' then
            exit(false);

        exit(Evaluate(DateValue, Value, 9));
    end;

    local procedure TryParseDecimal(Value: Text; var DecimalValue: Decimal): Boolean
    begin
        Value := CleanValue(Value);
        if Value = '' then begin
            DecimalValue := 0;
            exit(true);
        end;

        exit(Evaluate(DecimalValue, Value, 9));
    end;

    local procedure MapTransactionType(Action: Text): Enum "PTE Broker Transaction Type"
    begin
        case NormalizeField(Action) of
            'MARKET BUY':
                exit("PTE Broker Transaction Type"::Buy);
            'MARKET SELL':
                exit("PTE Broker Transaction Type"::Sell);
            'DIVIDEND (DIVIDEND)':
                exit("PTE Broker Transaction Type"::Dividend);
            'LENDING INTEREST':
                exit("PTE Broker Transaction Type"::Interest);
            'DEPOSIT':
                exit("PTE Broker Transaction Type"::Deposit);
            'WITHDRAWAL':
                exit("PTE Broker Transaction Type"::Withdrawal);
        end;

        exit("PTE Broker Transaction Type"::Other);
    end;

    local procedure MapInstrumentType(Action: Text; Symbol: Text): Enum "PTE Instrument Type"
    begin
        if Symbol = '' then
            exit("PTE Instrument Type"::Cash);
        if NormalizeField(Action) in ['MARKET BUY', 'MARKET SELL', 'DIVIDEND (DIVIDEND)', 'TRANSFER OUT'] then
            exit("PTE Instrument Type"::Stock);

        exit("PTE Instrument Type"::Other);
    end;

    local procedure BuildDuplicateCheckKey(ImportLine: Record "PTE Broker Import Line"): Text[250]
    var
        DuplicateCheckKey: Text;
    begin
        if ImportLine."External Entry ID" <> '' then
            DuplicateCheckKey := ImportLine."Broker Code" + '|' + ImportLine."External Entry ID"
        else
            DuplicateCheckKey := ImportLine."Broker Code" + '|' + Format(ImportLine."Trade Date", 0, 9) + '|' + ImportLine."Source Transaction Type" + '|' + ImportLine.Ticker + '|' + Format(ImportLine.Quantity, 0, 9) + '|' + Format(ImportLine."Gross Amount", 0, 9) + '|' + ImportLine.Description;

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
        InvalidSchemaErr: Label 'The file does not match the Trading 212 transaction CSV schema.';
        MissingHeaderErr: Label 'The Trading 212 CSV header was not found.';
        MissingTransactionLinesErr: Label 'No transaction lines were found in the Trading 212 report.';
        InvalidTradeDateErr: Label 'Trade date could not be parsed.';
        InvalidQuantityErr: Label 'Quantity could not be parsed.';
        InvalidPriceErr: Label 'Price could not be parsed.';
        InvalidTotalErr: Label 'Total amount could not be parsed.';
        InvalidFeeErr: Label 'Currency conversion fee could not be parsed.';
        InvalidTaxErr: Label 'Withholding tax could not be parsed.';
}