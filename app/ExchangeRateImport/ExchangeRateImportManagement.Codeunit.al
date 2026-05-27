codeunit 50100 "PTE Exch. Rate Import Mgmt."
{
    procedure ImportExchangeRates(StartDate: Date; EndDate: Date; CurrencyCodeFilter: Text; ReplaceExisting: Boolean): Integer
    var
        LCYCode: Code[10];
        ImportedCount: Integer;
    begin
        if StartDate = 0D then
            Error(StartDateRequiredErr);
        if EndDate = 0D then
            Error(EndDateRequiredErr);
        if StartDate > EndDate then
            Error(InvalidPeriodErr);

        LCYCode := GetLCYCode();
        ImportedCount += ImportSource("PTE Exch. Rate Source"::ECB, StartDate, EndDate, CurrencyCodeFilter, LCYCode, ReplaceExisting);
        ImportedCount += ImportSource("PTE Exch. Rate Source"::NBU, StartDate, EndDate, CurrencyCodeFilter, LCYCode, ReplaceExisting);
        ImportedCount += ImportSource("PTE Exch. Rate Source"::NBP, StartDate, EndDate, CurrencyCodeFilter, LCYCode, ReplaceExisting);
        exit(ImportedCount);
    end;

    local procedure ImportSource(Source: Enum "PTE Exch. Rate Source"; StartDate: Date; EndDate: Date; CurrencyCodeFilter: Text; LCYCode: Code[10]; ReplaceExisting: Boolean): Integer
    var
        Currency: Record Currency;
        BaseRates: Dictionary of [Text, Decimal];
        CurrencyCodes: List of [Code[10]];
        CurrentDate: Date;
        BaseCurrencyCode: Code[10];
        BasePerLCY: Decimal;
        ImportedCount: Integer;
    begin
        Currency.SetRange("PTE Exch. Rate Source", Source);
        if CurrencyCodeFilter <> '' then
            Currency.SetFilter(Code, CurrencyCodeFilter);

        if Currency.FindSet() then
            repeat
                if Currency.Code <> LCYCode then
                    if not CurrencyCodes.Contains(Currency.Code) then
                        CurrencyCodes.Add(Currency.Code);
            until Currency.Next() = 0;

        if CurrencyCodes.Count() = 0 then
            exit(0);

        BaseCurrencyCode := GetSourceBaseCurrencyCode(Source);
        LoadSourceRates(Source, StartDate, EndDate, CurrencyCodes, LCYCode, BaseRates);

        CurrentDate := StartDate;
        while CurrentDate <= EndDate do begin
            if GetBasePerCurrency(BaseRates, CurrentDate, LCYCode, BaseCurrencyCode, BasePerLCY) then
                ImportedCount += ImportRatesForDate(BaseRates, CurrentDate, CurrencyCodes, BaseCurrencyCode, BasePerLCY, ReplaceExisting);

            CurrentDate := CurrentDate + 1;
        end;

        exit(ImportedCount);
    end;

    local procedure ImportRatesForDate(BaseRates: Dictionary of [Text, Decimal]; StartingDate: Date; CurrencyCodes: List of [Code[10]]; BaseCurrencyCode: Code[10]; BasePerLCY: Decimal; ReplaceExisting: Boolean): Integer
    var
        CurrencyCode: Code[10];
        BasePerCurrency: Decimal;
        ImportedCount: Integer;
    begin
        foreach CurrencyCode in CurrencyCodes do
            if GetBasePerCurrency(BaseRates, StartingDate, CurrencyCode, BaseCurrencyCode, BasePerCurrency) then
                if UpsertExchangeRate(CurrencyCode, StartingDate, BasePerCurrency / BasePerLCY, ReplaceExisting) then
                    ImportedCount += 1;

        exit(ImportedCount);
    end;

    local procedure LoadSourceRates(Source: Enum "PTE Exch. Rate Source"; StartDate: Date; EndDate: Date; CurrencyCodes: List of [Code[10]]; LCYCode: Code[10]; var BaseRates: Dictionary of [Text, Decimal])
    begin
        Clear(BaseRates);
        EnsureCurrencyCode(CurrencyCodes, LCYCode);

        case Source of
            Source::ECB:
                LoadECBRates(StartDate, EndDate, CurrencyCodes, BaseRates);
            Source::NBU:
                LoadNBURates(StartDate, EndDate, CurrencyCodes, BaseRates);
            Source::NBP:
                LoadNBPRates(StartDate, EndDate, CurrencyCodes, BaseRates);
        end;
    end;

    local procedure LoadECBRates(StartDate: Date; EndDate: Date; CurrencyCodes: List of [Code[10]]; var BaseRates: Dictionary of [Text, Decimal])
    var
        TempBlob: Codeunit "Temp Blob";
        CsvInStream: InStream;
        CsvOutStream: OutStream;
        HeaderFields: List of [Text];
        CsvFields: List of [Text];
        ResponseText: Text;
        LineText: Text;
        StartingDate: Date;
        HeaderFound: Boolean;
    begin
        if not GetResponseText(ECBHistoryUrlTxt, ResponseText) then
            exit;

        TempBlob.CreateOutStream(CsvOutStream);
        CsvOutStream.WriteText(ResponseText);
        TempBlob.CreateInStream(CsvInStream);

        while not CsvInStream.EOS do begin
            CsvInStream.ReadText(LineText);
            ParseCsvLine(LineText, CsvFields);
            if not HeaderFound then begin
                HeaderFields := CsvFields;
                HeaderFound := true;
            end else
                if TryParseDate(GetField(CsvFields, 1), StartingDate) then
                    LoadECBLineRates(StartDate, EndDate, StartingDate, HeaderFields, CsvFields, CurrencyCodes, BaseRates);
        end;
    end;

    local procedure LoadECBLineRates(StartDate: Date; EndDate: Date; StartingDate: Date; HeaderFields: List of [Text]; CsvFields: List of [Text]; CurrencyCodes: List of [Code[10]]; var BaseRates: Dictionary of [Text, Decimal])
    var
        FieldIndex: Integer;
        CurrencyCode: Code[10];
        SourceRate: Decimal;
    begin
        if (StartingDate < StartDate) or (StartingDate > EndDate) then
            exit;

        AddBaseRate(BaseRates, StartingDate, 'EUR', 1);
        foreach CurrencyCode in CurrencyCodes do
            if CurrencyCode <> 'EUR' then begin
                FieldIndex := GetFieldIndex(HeaderFields, CurrencyCode);
                if FieldIndex <> 0 then
                    if TryParseDecimal(GetField(CsvFields, FieldIndex), SourceRate) then
                        if SourceRate <> 0 then
                            AddBaseRate(BaseRates, StartingDate, CurrencyCode, 1 / SourceRate);
            end;
    end;

    local procedure LoadNBURates(StartDate: Date; EndDate: Date; CurrencyCodes: List of [Code[10]]; var BaseRates: Dictionary of [Text, Decimal])
    var
        RatesArray: JsonArray;
        RateObject: JsonObject;
        RateToken: JsonToken;
        ResponseText: Text;
        CurrencyCode: Code[10];
        CurrentDate: Date;
        Index: Integer;
    begin
        CurrentDate := StartDate;
        while CurrentDate <= EndDate do begin
            if GetResponseText(StrSubstNo(NBUDateUrlTxt, FormatDateCompact(CurrentDate)), ResponseText) then begin
                if not RatesArray.ReadFrom(ResponseText) then
                    Error(InvalidJsonErr, 'NBU');

                AddBaseRate(BaseRates, CurrentDate, 'UAH', 1);
                for Index := 0 to RatesArray.Count() - 1 do begin
                    RatesArray.Get(Index, RateToken);
                    RateObject := RateToken.AsObject();
                    CurrencyCode := CopyStr(UpperCase(GetJsonText(RateObject, 'cc')), 1, MaxStrLen(CurrencyCode));
                    if CurrencyCodes.Contains(CurrencyCode) then
                        AddBaseRate(BaseRates, CurrentDate, CurrencyCode, GetJsonDecimal(RateObject, 'rate'));
                end;
            end;

            Clear(RatesArray);
            CurrentDate := CurrentDate + 1;
        end;
    end;

    local procedure LoadNBPRates(StartDate: Date; EndDate: Date; CurrencyCodes: List of [Code[10]]; var BaseRates: Dictionary of [Text, Decimal])
    var
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        PeriodStartDate := StartDate;
        while PeriodStartDate <= EndDate do begin
            PeriodEndDate := PeriodStartDate + 92;
            if PeriodEndDate > EndDate then
                PeriodEndDate := EndDate;

            LoadNBPTableRates('A', PeriodStartDate, PeriodEndDate, CurrencyCodes, BaseRates);
            LoadNBPTableRates('B', PeriodStartDate, PeriodEndDate, CurrencyCodes, BaseRates);
            PeriodStartDate := PeriodEndDate + 1;
        end;
    end;

    local procedure LoadNBPTableRates(TableType: Text[1]; StartDate: Date; EndDate: Date; CurrencyCodes: List of [Code[10]]; var BaseRates: Dictionary of [Text, Decimal])
    var
        TablesArray: JsonArray;
        RatesArray: JsonArray;
        TableToken: JsonToken;
        RateToken: JsonToken;
        TableObject: JsonObject;
        RateObject: JsonObject;
        ResponseText: Text;
        CurrencyCode: Code[10];
        EffectiveDate: Date;
        TableIndex: Integer;
        RateIndex: Integer;
    begin
        if not GetResponseText(StrSubstNo(NBPTablesUrlTxt, LowerCase(TableType), FormatDate(StartDate), FormatDate(EndDate)), ResponseText) then
            exit;

        if not TablesArray.ReadFrom(ResponseText) then
            Error(InvalidJsonErr, 'NBP');

        for TableIndex := 0 to TablesArray.Count() - 1 do begin
            TablesArray.Get(TableIndex, TableToken);
            TableObject := TableToken.AsObject();
            EffectiveDate := GetJsonDate(TableObject, 'effectiveDate');
            RatesArray := GetJsonArray(TableObject, 'rates');
            AddBaseRate(BaseRates, EffectiveDate, 'PLN', 1);

            for RateIndex := 0 to RatesArray.Count() - 1 do begin
                RatesArray.Get(RateIndex, RateToken);
                RateObject := RateToken.AsObject();
                CurrencyCode := CopyStr(UpperCase(GetJsonText(RateObject, 'code')), 1, MaxStrLen(CurrencyCode));
                if CurrencyCodes.Contains(CurrencyCode) then
                    AddBaseRate(BaseRates, EffectiveDate, CurrencyCode, GetJsonDecimal(RateObject, 'mid'));
            end;
        end;
    end;

    local procedure UpsertExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; LCYPerCurrency: Decimal; ReplaceExisting: Boolean): Boolean
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        RoundedRate: Decimal;
        Exists: Boolean;
    begin
        if LCYPerCurrency = 0 then
            exit(false);

        RoundedRate := Round(LCYPerCurrency, 0.0000001, '=');
        Exists := CurrencyExchangeRate.Get(CurrencyCode, StartingDate);
        if Exists and not ReplaceExisting then
            exit(false);

        if not Exists then begin
            CurrencyExchangeRate.Init();
            CurrencyExchangeRate."Currency Code" := CurrencyCode;
            CurrencyExchangeRate."Starting Date" := StartingDate;
        end;

        CurrencyExchangeRate."Exchange Rate Amount" := 1;
        CurrencyExchangeRate."Adjustment Exch. Rate Amount" := 1;
        CurrencyExchangeRate."Relational Currency Code" := '';
        CurrencyExchangeRate."Relational Exch. Rate Amount" := RoundedRate;
        CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" := RoundedRate;

        if Exists then
            CurrencyExchangeRate.Modify(true)
        else
            CurrencyExchangeRate.Insert(true);

        exit(true);
    end;

    local procedure GetResponseText(Url: Text; var ResponseText: Text): Boolean
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        if not Client.Get(Url, Response) then
            Error(RequestBlockedErr);

        Response.Content().ReadAs(ResponseText);
        if Response.HttpStatusCode() = 404 then
            exit(false);
        if not Response.IsSuccessStatusCode() then
            Error(RequestFailedErr, Url, Response.HttpStatusCode(), CopyStr(ResponseText, 1, 500));

        exit(true);
    end;

    local procedure AddBaseRate(var BaseRates: Dictionary of [Text, Decimal]; StartingDate: Date; CurrencyCode: Code[10]; BasePerCurrency: Decimal)
    var
        RateKey: Text;
    begin
        RateKey := GetRateKey(StartingDate, CurrencyCode);
        if BaseRates.ContainsKey(RateKey) then
            BaseRates.Set(RateKey, BasePerCurrency)
        else
            BaseRates.Add(RateKey, BasePerCurrency);
    end;

    local procedure GetBasePerCurrency(BaseRates: Dictionary of [Text, Decimal]; StartingDate: Date; CurrencyCode: Code[10]; BaseCurrencyCode: Code[10]; var BasePerCurrency: Decimal): Boolean
    begin
        if CurrencyCode = BaseCurrencyCode then begin
            BasePerCurrency := 1;
            exit(true);
        end;

        exit(BaseRates.Get(GetRateKey(StartingDate, CurrencyCode), BasePerCurrency));
    end;

    local procedure GetRateKey(StartingDate: Date; CurrencyCode: Code[10]): Text
    begin
        exit(FormatDate(StartingDate) + '|' + CurrencyCode);
    end;

    local procedure GetSourceBaseCurrencyCode(Source: Enum "PTE Exch. Rate Source"): Code[10]
    begin
        case Source of
            Source::ECB:
                exit('EUR');
            Source::NBU:
                exit('UAH');
            Source::NBP:
                exit('PLN');
        end;
    end;

    local procedure EnsureCurrencyCode(var CurrencyCodes: List of [Code[10]]; CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then
            exit;
        if not CurrencyCodes.Contains(CurrencyCode) then
            CurrencyCodes.Add(CurrencyCode);
    end;

    local procedure GetLCYCode(): Code[10]
    var
        InvestSetup: Record "PTE Invest Setup";
        GLSetup: Record "General Ledger Setup";
    begin
        if InvestSetup.Get() then
            if InvestSetup."LCY Currency Code" <> '' then
                exit(InvestSetup."LCY Currency Code");

        GLSetup.Get();
        if GLSetup."LCY Code" <> '' then
            exit(GLSetup."LCY Code");

        Error(LCYRequiredErr);
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

    local procedure GetField(CsvFields: List of [Text]; FieldIndex: Integer): Text
    var
        Value: Text;
    begin
        if (FieldIndex <= 0) or (FieldIndex > CsvFields.Count()) then
            exit('');

        CsvFields.Get(FieldIndex, Value);
        exit(CleanValue(Value));
    end;

    local procedure GetFieldIndex(HeaderFields: List of [Text]; FieldName: Text): Integer
    var
        Index: Integer;
    begin
        for Index := 1 to HeaderFields.Count() do
            if UpperCase(GetField(HeaderFields, Index)) = UpperCase(FieldName) then
                exit(Index);

        exit(0);
    end;

    local procedure CleanValue(Value: Text): Text
    begin
        exit(DelChr(Value, '<>', ' '));
    end;

    local procedure TryParseDate(Value: Text; var DateValue: Date): Boolean
    begin
        Value := CleanValue(Value);
        if Value = '' then
            exit(false);

        exit(Evaluate(DateValue, Value, 9));
    end;

    local procedure TryParseDecimal(Value: Text; var DecimalValue: Decimal): Boolean
    begin
        Value := CleanValue(Value);
        if Value = '' then
            exit(false);

        exit(Evaluate(DecimalValue, Value, 9));
    end;

    local procedure FormatDate(Value: Date): Text
    begin
        exit(StrSubstNo('%1-%2-%3', Format(Date2DMY(Value, 3)), Pad2(Date2DMY(Value, 2)), Pad2(Date2DMY(Value, 1))));
    end;

    local procedure FormatDateCompact(Value: Date): Text
    begin
        exit(StrSubstNo('%1%2%3', Format(Date2DMY(Value, 3)), Pad2(Date2DMY(Value, 2)), Pad2(Date2DMY(Value, 1))));
    end;

    local procedure Pad2(Value: Integer): Text[2]
    begin
        if Value < 10 then
            exit('0' + Format(Value));

        exit(CopyStr(Format(Value), 1, 2));
    end;

    local procedure GetJsonText(JsonObject: JsonObject; PropertyName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if not JsonObject.Get(PropertyName, JsonToken) then
            Error(MissingJsonPropertyErr, PropertyName);

        exit(JsonToken.AsValue().AsText());
    end;

    local procedure GetJsonDecimal(JsonObject: JsonObject; PropertyName: Text): Decimal
    var
        JsonToken: JsonToken;
    begin
        if not JsonObject.Get(PropertyName, JsonToken) then
            Error(MissingJsonPropertyErr, PropertyName);

        exit(JsonToken.AsValue().AsDecimal());
    end;

    local procedure GetJsonDate(JsonObject: JsonObject; PropertyName: Text): Date
    var
        DateValue: Date;
    begin
        if not Evaluate(DateValue, GetJsonText(JsonObject, PropertyName), 9) then
            Error(InvalidJsonDateErr, PropertyName);

        exit(DateValue);
    end;

    local procedure GetJsonArray(JsonObject: JsonObject; PropertyName: Text): JsonArray
    var
        JsonToken: JsonToken;
    begin
        if not JsonObject.Get(PropertyName, JsonToken) then
            Error(MissingJsonPropertyErr, PropertyName);

        exit(JsonToken.AsArray());
    end;

    var
        StartDateRequiredErr: Label 'Start date must be specified.';
        EndDateRequiredErr: Label 'End date must be specified.';
        InvalidPeriodErr: Label 'Start date cannot be later than end date.';
        LCYRequiredErr: Label 'LCY currency code must be specified in Invest Setup or General Ledger Setup.';
        RequestBlockedErr: Label 'The exchange rate request could not be sent. Enable HTTP client requests for this extension.';
        RequestFailedErr: Label 'The exchange rate request failed. URL: %1. HTTP status code: %2. Response: %3', Comment = '%1 = request URL, %2 = HTTP status code, %3 = response body';
        InvalidJsonErr: Label 'The %1 exchange rate response is not valid JSON.', Comment = '%1 = exchange rate source';
        MissingJsonPropertyErr: Label 'The exchange rate response does not contain the required property %1.', Comment = '%1 = JSON property name';
        InvalidJsonDateErr: Label 'The exchange rate response contains an invalid date in property %1.', Comment = '%1 = JSON property name';
        ECBHistoryUrlTxt: Label 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.csv', Locked = true;
        NBPTablesUrlTxt: Label 'https://api.nbp.pl/api/exchangerates/tables/%1/%2/%3/?format=json', Locked = true, Comment = '%1 = NBP table type, %2 = start date, %3 = end date';
        NBUDateUrlTxt: Label 'https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?date=%1&json', Locked = true, Comment = '%1 = date in yyyymmdd format';
}
