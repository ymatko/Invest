codeunit 50112 "PTE Broker Import Management"
{
    procedure CreateImportHeader(Broker: Record "PTE Broker"; SourceFileName: Text; var ImportHeader: Record "PTE Broker Import Header")
    begin
        ImportHeader.Init();
        ImportHeader."Broker Code" := Broker.Code;
        ImportHeader."Import Provider" := Broker."Import Provider";
        ImportHeader."Source File Name" := CopyStr(SourceFileName, 1, MaxStrLen(ImportHeader."Source File Name"));
        ImportHeader.Status := ImportHeader.Status::Created;
        ImportHeader.Insert(true);
    end;

    procedure ValidateImport(var ImportHeader: Record "PTE Broker Import Header")
    var
        ImportLine: Record "PTE Broker Import Line";
    begin
        ImportLine.SetRange("Import Entry No.", ImportHeader."Entry No.");
        if ImportLine.FindSet() then
            repeat
                ValidateImportLine(ImportLine);
            until ImportLine.Next() = 0;

        UpdateHeaderCounts(ImportHeader);
        if ImportHeader.Status <> ImportHeader.Status::Failed then
            ImportHeader.Status := ImportHeader.Status::Validated;
        ImportHeader.Modify();
    end;

    procedure ImportValidLines(var ImportHeader: Record "PTE Broker Import Header")
    var
        ImportLine: Record "PTE Broker Import Line";
    begin
        ValidateImport(ImportHeader);
        ImportHeader.TestField(Status, ImportHeader.Status::Validated);

        ImportLine.SetRange("Import Entry No.", ImportHeader."Entry No.");
        ImportLine.SetRange(Status, ImportLine.Status::Valid);
        ImportLine.SetRange(Selected, true);
        if ImportLine.IsEmpty() then
            Error(NoValidLinesToImportErr);

        if ImportLine.FindSet(true) then
            repeat
                CreateBrokerEntry(ImportHeader, ImportLine);
            until ImportLine.Next() = 0;

        UpdateHeaderCounts(ImportHeader);
        if ImportHeader."Error Lines" = 0 then
            ImportHeader.Status := ImportHeader.Status::Imported
        else
            ImportHeader.Status := ImportHeader.Status::PartiallyImported;
        ImportHeader."Imported At" := CurrentDateTime;
        ImportHeader."Imported By" := CopyStr(UserId(), 1, MaxStrLen(ImportHeader."Imported By"));
        ImportHeader.Modify();
    end;

    procedure UpdateHeaderCounts(var ImportHeader: Record "PTE Broker Import Header")
    var
        ImportLine: Record "PTE Broker Import Line";
    begin
        ImportLine.SetRange("Import Entry No.", ImportHeader."Entry No.");
        ImportHeader."Total Lines" := ImportLine.Count();

        ImportLine.SetRange(Status, ImportLine.Status::Valid);
        ImportHeader."Valid Lines" := ImportLine.Count();

        ImportLine.SetRange(Status, ImportLine.Status::Error);
        ImportHeader."Error Lines" := ImportLine.Count();

        ImportLine.SetRange(Status, ImportLine.Status::Imported);
        ImportHeader."Imported Lines" := ImportLine.Count();
        ImportLine.SetRange(Status);
    end;

    local procedure ValidateImportLine(var ImportLine: Record "PTE Broker Import Line")
    var
        BrokerEntry: Record "PTE Broker Entry";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        DuplicateImportLine: Record "PTE Broker Import Line";
        CurrencyFactor: Decimal;
        ExchangeRateDate: Date;
    begin
        if ImportLine.Status = ImportLine.Status::Imported then
            exit;

        if ImportLine."Provider Error" then begin
            ImportLine.Status := ImportLine.Status::Error;
            ImportLine.Modify();
            exit;
        end;

        ImportLine.Status := ImportLine.Status::Valid;
        ImportLine."Validation Message" := '';

        if not ImportLine.Selected then begin
            ImportLine.Status := ImportLine.Status::Skipped;
            ImportLine.Modify();
            exit;
        end;

        if ImportLine."Broker Code" = '' then
            SetLineError(ImportLine, MissingBrokerErr);
        if ImportLine."Trade Date" = 0D then
            SetLineError(ImportLine, MissingTradeDateErr);
        if ImportLine."Currency Code" = '' then
            SetLineError(ImportLine, MissingCurrencyErr);
        if ImportLine."Duplicate Check Key" = '' then
            SetLineError(ImportLine, MissingDuplicateKeyErr);

        SetCountryFromISIN(ImportLine);

        if ImportLine.Status = ImportLine.Status::Error then begin
            ImportLine.Modify();
            exit;
        end;

        BrokerEntry.SetRange("Duplicate Check Key", ImportLine."Duplicate Check Key");
        if not BrokerEntry.IsEmpty() then
            SetLineError(ImportLine, DuplicateBrokerEntryErr);

        DuplicateImportLine.SetRange("Import Entry No.", ImportLine."Import Entry No.");
        DuplicateImportLine.SetRange("Duplicate Check Key", ImportLine."Duplicate Check Key");
        DuplicateImportLine.SetFilter("Line No.", '<>%1', ImportLine."Line No.");
        if not DuplicateImportLine.IsEmpty() then
            SetLineError(ImportLine, DuplicateImportLineErr);

        GLSetup.Get();
        if ImportLine."Currency Code" <> GLSetup."LCY Code" then begin
            if not Currency.Get(ImportLine."Currency Code") then
                SetLineError(ImportLine, MissingCurrencyRecordErr);
            ExchangeRateDate := GetExchangeRateDate(ImportLine, ImportLine."Currency Code");
            if ExchangeRateDate = 0D then
                SetLineError(ImportLine, MissingExchangeRateErr);
        end;

        if (ImportLine."Price Currency Code" <> '') and (ImportLine."Price Currency Code" <> GLSetup."LCY Code") then
            if not Currency.Get(ImportLine."Price Currency Code") then
                SetLineError(ImportLine, MissingPriceCurrencyRecordErr);

        if ImportLine.Status <> ImportLine.Status::Valid then begin
            ImportLine.Modify();
            exit;
        end;

        if ImportLine."Currency Code" = GLSetup."LCY Code" then begin
            ImportLine."Exchange Rate" := 1;
            ImportLine."LCY Gross Amount" := ImportLine."Gross Amount";
            ImportLine."LCY Fee Amount" := ImportLine."Fee Amount";
            ImportLine."LCY Tax Amount" := ImportLine."Tax Amount";
            ImportLine."LCY Net Amount" := ImportLine."Net Amount";
        end else begin
            CurrencyFactor := CurrencyExchangeRate.ExchangeRate(ExchangeRateDate, ImportLine."Currency Code");
            ImportLine."Exchange Rate" := CurrencyFactor;
            ImportLine."LCY Gross Amount" := CurrencyExchangeRate.ExchangeAmtFCYToLCY(ExchangeRateDate, ImportLine."Currency Code", ImportLine."Gross Amount", CurrencyFactor);
            ImportLine."LCY Fee Amount" := CurrencyExchangeRate.ExchangeAmtFCYToLCY(ExchangeRateDate, ImportLine."Currency Code", ImportLine."Fee Amount", CurrencyFactor);
            ImportLine."LCY Tax Amount" := CurrencyExchangeRate.ExchangeAmtFCYToLCY(ExchangeRateDate, ImportLine."Currency Code", ImportLine."Tax Amount", CurrencyFactor);
            ImportLine."LCY Net Amount" := CurrencyExchangeRate.ExchangeAmtFCYToLCY(ExchangeRateDate, ImportLine."Currency Code", ImportLine."Net Amount", CurrencyFactor);
        end;

        ImportLine.Modify();
    end;

    local procedure GetExchangeRateDate(ImportLine: Record "PTE Broker Import Line"; CurrencyCode: Code[10]): Date
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ReferenceDate: Date;
    begin
        ReferenceDate := ImportLine."Trade Date";
        if ImportLine."Settlement Date" <> 0D then
            ReferenceDate := ImportLine."Settlement Date";
        if ReferenceDate = 0D then
            exit(0D);

        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.SetFilter("Starting Date", '..%1', CalcDate('<-1D>', ReferenceDate));
        if CurrencyExchangeRate.FindLast() then
            exit(CurrencyExchangeRate."Starting Date");

        exit(0D);
    end;

    local procedure CreateBrokerEntry(ImportHeader: Record "PTE Broker Import Header"; var ImportLine: Record "PTE Broker Import Line")
    var
        BrokerEntry: Record "PTE Broker Entry";
    begin
        if ImportLine."Duplicate Check Key" = '' then begin
            SetLineError(ImportLine, MissingDuplicateKeyErr);
            ImportLine.Modify();
            exit;
        end;

        BrokerEntry.SetRange("Duplicate Check Key", ImportLine."Duplicate Check Key");
        if not BrokerEntry.IsEmpty() then begin
            SetLineError(ImportLine, DuplicateBrokerEntryErr);
            ImportLine.Modify();
            exit;
        end;

        BrokerEntry.Reset();
        BrokerEntry.Init();
        SetCountryFromISIN(ImportLine);
        BrokerEntry.Validate("Broker Code", ImportLine."Broker Code");
        BrokerEntry."External Entry ID" := ImportLine."External Entry ID";
        BrokerEntry."Broker Account No." := ImportLine."Broker Account No.";
        BrokerEntry."Transaction Type" := ImportLine."Transaction Type";
        BrokerEntry."Source Transaction Type" := ImportLine."Source Transaction Type";
        BrokerEntry."Instrument Type" := ImportLine."Instrument Type";
        BrokerEntry.Validate("Trade Date", ImportLine."Trade Date");
        BrokerEntry."Settlement Date" := ImportLine."Settlement Date";
        BrokerEntry."Tax Year" := ImportLine."Tax Year";
        BrokerEntry.ISIN := ImportLine.ISIN;
        BrokerEntry.Ticker := ImportLine.Ticker;
        BrokerEntry.Description := ImportLine.Description;
        BrokerEntry."Country/Region Code" := ImportLine."Country/Region Code";
        BrokerEntry.Quantity := ImportLine.Quantity;
        BrokerEntry.Price := ImportLine.Price;
        BrokerEntry."Price Currency Code" := ImportLine."Price Currency Code";
        BrokerEntry."Currency Code" := ImportLine."Currency Code";
        BrokerEntry."Gross Amount" := ImportLine."Gross Amount";
        BrokerEntry."Fee Amount" := ImportLine."Fee Amount";
        BrokerEntry."Tax Amount" := ImportLine."Tax Amount";
        BrokerEntry."Net Amount" := ImportLine."Net Amount";
        BrokerEntry."Exchange Rate" := ImportLine."Exchange Rate";
        BrokerEntry."LCY Gross Amount" := ImportLine."LCY Gross Amount";
        BrokerEntry."LCY Fee Amount" := ImportLine."LCY Fee Amount";
        BrokerEntry."LCY Tax Amount" := ImportLine."LCY Tax Amount";
        BrokerEntry."LCY Net Amount" := ImportLine."LCY Net Amount";
        BrokerEntry."Import Batch No." := CopyStr(Format(ImportHeader."Entry No."), 1, MaxStrLen(BrokerEntry."Import Batch No."));
        BrokerEntry."Broker Import Entry No." := ImportHeader."Entry No.";
        BrokerEntry."Source File Name" := ImportLine."Source File Name";
        BrokerEntry."Source Line No." := ImportLine."Source Line No.";
        BrokerEntry."Duplicate Check Key" := ImportLine."Duplicate Check Key";
        BrokerEntry.Insert(true);

        ImportLine.Status := ImportLine.Status::Imported;
        ImportLine."Broker Entry No." := BrokerEntry."Entry No.";
        ImportLine.Modify();
    end;

    local procedure SetCountryFromISIN(var ImportLine: Record "PTE Broker Import Line")
    var
        Broker: Record "PTE Broker";
    begin
        if ImportLine."Country/Region Code" <> '' then
            exit;
        if StrLen(ImportLine.ISIN) >= 2 then begin
            ImportLine."Country/Region Code" := CopyStr(ImportLine.ISIN, 1, 2);
            exit;
        end;

        if (ImportLine."Transaction Type" = ImportLine."Transaction Type"::Interest) and (ImportLine."Instrument Type" = ImportLine."Instrument Type"::Cash) then
            if Broker.Get(ImportLine."Broker Code") then
                ImportLine."Country/Region Code" := Broker."Country/Region Code";
    end;

    local procedure SetLineError(var ImportLine: Record "PTE Broker Import Line"; ErrorMessage: Text)
    begin
        ImportLine.Status := ImportLine.Status::Error;
        if ImportLine."Validation Message" = '' then
            ImportLine."Validation Message" := CopyStr(ErrorMessage, 1, MaxStrLen(ImportLine."Validation Message"));
    end;

    var
        NoValidLinesToImportErr: Label 'There are no selected valid lines to import.';
        MissingBrokerErr: Label 'Broker code is missing.';
        MissingTradeDateErr: Label 'Trade date is missing.';
        MissingCurrencyErr: Label 'Currency code is missing.';
        MissingDuplicateKeyErr: Label 'Duplicate check key is missing.';
        DuplicateBrokerEntryErr: Label 'A broker entry with the same duplicate check key already exists.';
        DuplicateImportLineErr: Label 'Another line in this import has the same duplicate check key.';
        MissingCurrencyRecordErr: Label 'Currency does not exist in Business Central.';
        MissingPriceCurrencyRecordErr: Label 'Price currency does not exist in Business Central.';
        MissingExchangeRateErr: Label 'Currency exchange rate does not exist for the tax exchange rate date.';
}