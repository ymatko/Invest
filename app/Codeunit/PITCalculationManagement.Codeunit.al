codeunit 50116 "PTE PIT Calc. Mgmt."
{
    procedure CreateCalculation(TaxYear: Integer; StartDate: Date; EndDate: Date; PriorLossDeduction: Decimal; var PITCalculation: Record "PTE PIT Calculation")
    var
        InvestSetup: Record "PTE Invest Setup";
        BrokerEntry: Record "PTE Broker Entry";
        BuyLots: Dictionary of [Text, List of [Decimal]];
        CountryIncome: Dictionary of [Code[10], Decimal];
        CountryTax: Dictionary of [Code[10], Decimal];
        TaxCountryCode: Code[10];
        TotalRevenue: Decimal;
        TotalCost: Decimal;
        TotalForeignTaxPaid: Decimal;
        FlatTaxableIncome: Decimal;
        FlatForeignTaxPaid: Decimal;
        SourceEntryCount: Integer;
        WarningCount: Integer;
        Income: Decimal;
        Loss: Decimal;
        TaxBase: Decimal;
        TaxBeforeForeignTax: Decimal;
        SecuritiesTaxDue: Decimal;
        FlatTaxBeforeForeignTax: Decimal;
        FlatTaxDue: Decimal;
        TotalTaxDue: Decimal;
    begin
        if TaxYear = 0 then
            Error(TaxYearRequiredErr);
        if StartDate = 0D then
            Error(StartDateRequiredErr);
        if EndDate = 0D then
            Error(EndDateRequiredErr);
        if StartDate > EndDate then
            Error(InvalidPeriodErr);

        TaxCountryCode := 'PL';
        if InvestSetup.Get() then
            if InvestSetup."Tax Country/Region Code" <> '' then
                TaxCountryCode := InvestSetup."Tax Country/Region Code";

        PITCalculation.Init();
        PITCalculation."Tax Year" := TaxYear;
        PITCalculation."Period Start Date" := StartDate;
        PITCalculation."Period End Date" := EndDate;
        PITCalculation.Status := PITCalculation.Status::Created;
        PITCalculation."Tax Rate %" := 19;
        PITCalculation."Prior Loss Deduction" := PriorLossDeduction;
        PITCalculation.Insert(true);

        BrokerEntry.SetFilter("Trade Date", '..%1', EndDate);
        BrokerEntry.SetFilter("Transaction Type", '%1|%2', BrokerEntry."Transaction Type"::Buy, BrokerEntry."Transaction Type"::Sell);
        BrokerEntry.SetCurrentKey("Trade Date");
        if BrokerEntry.FindSet() then
            repeat
                if BrokerEntry."Transaction Type" = BrokerEntry."Transaction Type"::Buy then
                    AddBuyLot(BuyLots, BrokerEntry)
                else begin
                    if (BrokerEntry."Trade Date" >= StartDate) and (BrokerEntry."Trade Date" <= EndDate) then
                        SourceEntryCount += 1;

                    ProcessSellEntry(PITCalculation, BrokerEntry, BuyLots, CountryIncome, CountryTax, TaxCountryCode, StartDate, EndDate, TotalRevenue, TotalCost, TotalForeignTaxPaid, WarningCount);
                end;
            until BrokerEntry.Next() = 0;

        CalculateFlatTax(PITCalculation, StartDate, EndDate, TaxCountryCode, FlatTaxableIncome, FlatForeignTaxPaid, SourceEntryCount, WarningCount);

        Income := TotalRevenue - TotalCost;
        if Income < 0 then begin
            Loss := -Income;
            Income := 0;
        end;

        TaxBase := Income - PriorLossDeduction;
        if TaxBase < 0 then
            TaxBase := 0;
        TaxBase := Round(TaxBase, 1, '=');
        TaxBeforeForeignTax := Round(TaxBase * 0.19, 0.01, '=');
        SecuritiesTaxDue := Round(TaxBeforeForeignTax - TotalForeignTaxPaid, 1, '=');
        if SecuritiesTaxDue < 0 then
            SecuritiesTaxDue := 0;
        FlatTaxBeforeForeignTax := Round(FlatTaxableIncome * 0.19, 0.01, '=');
        if FlatForeignTaxPaid > FlatTaxBeforeForeignTax then
            FlatForeignTaxPaid := FlatTaxBeforeForeignTax;
        FlatTaxDue := Round(FlatTaxBeforeForeignTax - FlatForeignTaxPaid, 1, '=');
        if FlatTaxDue < 0 then
            FlatTaxDue := 0;
        TotalTaxDue := SecuritiesTaxDue + FlatTaxDue;

        PITCalculation."Source Entries" := SourceEntryCount;
        PITCalculation."PIT-38 Revenue" := Round(TotalRevenue, 0.01, '=');
        PITCalculation."PIT-38 Costs" := Round(TotalCost, 0.01, '=');
        PITCalculation."PIT-38 Income" := Round(Income, 0.01, '=');
        PITCalculation."PIT-38 Loss" := Round(Loss, 0.01, '=');
        PITCalculation."Tax Base" := TaxBase;
        PITCalculation."Tax Before Foreign Tax" := TaxBeforeForeignTax;
        PITCalculation."Foreign Tax Paid" := Round(TotalForeignTaxPaid, 0.01, '=');
        PITCalculation."Securities Tax Due" := SecuritiesTaxDue;
        PITCalculation."Flat Tax Before Foreign Tax" := FlatTaxBeforeForeignTax;
        PITCalculation."Flat Foreign Tax Paid" := Round(FlatForeignTaxPaid, 0.01, '=');
        PITCalculation."Flat Tax Due" := FlatTaxDue;
        PITCalculation."Tax Due" := TotalTaxDue;
        PITCalculation."Warning Count" := WarningCount;
        PITCalculation."PIT-ZG Countries" := CountPITZGCountries(CountryIncome);
        PITCalculation."PIT-ZG Required" := PITCalculation."PIT-ZG Countries" > 0;
        PITCalculation.Status := PITCalculation.Status::Calculated;
        PITCalculation.Modify();

        InsertPIT38Lines(PITCalculation);
        InsertPITZGLines(PITCalculation, CountryIncome, CountryTax);
    end;

    local procedure CalculateFlatTax(PITCalculation: Record "PTE PIT Calculation"; StartDate: Date; EndDate: Date; TaxCountryCode: Code[10]; var FlatTaxableIncome: Decimal; var FlatForeignTaxPaid: Decimal; var SourceEntryCount: Integer; var WarningCount: Integer)
    var
        BrokerEntry: Record "PTE Broker Entry";
        CountryCode: Code[10];
        TaxableAmount: Decimal;
    begin
        BrokerEntry.SetRange("Trade Date", StartDate, EndDate);
        BrokerEntry.SetFilter("Transaction Type", '%1|%2', BrokerEntry."Transaction Type"::Dividend, BrokerEntry."Transaction Type"::Interest);
        if BrokerEntry.FindSet() then
            repeat
                CountryCode := GetEntryCountryCode(BrokerEntry);
                if CountryCode = '' then begin
                    WarningCount += 1;
                    InsertLine(PITCalculation, 900000 + WarningCount, "PTE PIT Calc. Line Type"::Warning, 'CHECK', '', '', StrSubstNo(MissingCountryTxt, BrokerEntry."Entry No."), 0, BrokerEntry.Ticker, StrSubstNo(MissingCountryNoteTxt, BrokerEntry."Entry No.", BrokerEntry.Ticker, BrokerEntry.Description));
                end else
                    if CountryCode <> TaxCountryCode then begin
                        TaxableAmount := Abs(BrokerEntry."LCY Gross Amount");
                        FlatTaxableIncome += TaxableAmount;
                        FlatForeignTaxPaid += Abs(BrokerEntry."LCY Tax Amount");
                        SourceEntryCount += 1;
                    end;
            until BrokerEntry.Next() = 0;
    end;

    procedure ExportPIT38(PITCalculation: Record "PTE PIT Calculation")
    var
        PITCalcLine: Record "PTE PIT Calc. Line";
    begin
        PITCalcLine.SetRange("Calculation Entry No.", PITCalculation."Entry No.");
        PITCalcLine.SetRange("Line Type", PITCalcLine."Line Type"::PIT38);
        ExportLinesToExcel(PITCalculation, PITCalcLine, 'PIT-38', StrSubstNo(PIT38FileNameTxt, PITCalculation."Tax Year", PITCalculation."Entry No."));
    end;

    procedure ExportPITZG(PITCalculation: Record "PTE PIT Calculation")
    var
        PITCalcLine: Record "PTE PIT Calc. Line";
    begin
        PITCalculation.TestField("PIT-ZG Required", true);
        PITCalcLine.SetRange("Calculation Entry No.", PITCalculation."Entry No.");
        PITCalcLine.SetRange("Line Type", PITCalcLine."Line Type"::PITZG);
        ExportLinesToExcel(PITCalculation, PITCalcLine, 'PIT-ZG', StrSubstNo(PITZGFileNameTxt, PITCalculation."Tax Year", PITCalculation."Entry No."));
    end;

    procedure ExportPITArchive(PITCalculation: Record "PTE PIT Calculation")
    var
        TempBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        FileManagement: Codeunit "File Management";
        ZipInStream: InStream;
        ZipOutStream: OutStream;
    begin
        DataCompression.CreateZipArchive();
        AddPIT38ToZip(PITCalculation, DataCompression);
        if PITCalculation."PIT-ZG Required" then
            AddPITZGToZip(PITCalculation, DataCompression);

        TempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        DataCompression.CloseZipArchive();

        TempBlob.CreateInStream(ZipInStream);
        FileManagement.DownloadFromStreamHandler(ZipInStream, '', '', ZipFileFilterTxt, StrSubstNo(PITArchiveFileNameTxt, PITCalculation."Tax Year", PITCalculation."Entry No."));
    end;

    local procedure ProcessSellEntry(PITCalculation: Record "PTE PIT Calculation"; SellEntry: Record "PTE Broker Entry"; var BuyLots: Dictionary of [Text, List of [Decimal]]; var CountryIncome: Dictionary of [Code[10], Decimal]; var CountryTax: Dictionary of [Code[10], Decimal]; TaxCountryCode: Code[10]; StartDate: Date; EndDate: Date; var TotalRevenue: Decimal; var TotalCost: Decimal; var TotalForeignTaxPaid: Decimal; var WarningCount: Integer)
    var
        CountryCode: Code[10];
        InstrumentKey: Text;
        MatchedCost: Decimal;
        SellCost: Decimal;
        SellIncome: Decimal;
        Revenue: Decimal;
        ForeignTaxPaid: Decimal;
        UnmatchedQuantity: Decimal;
    begin
        InstrumentKey := GetInstrumentKey(SellEntry);
        Revenue := Abs(SellEntry."LCY Gross Amount");
        SellCost := Abs(SellEntry."LCY Fee Amount");
        MatchedCost := ConsumeBuyLots(BuyLots, InstrumentKey, Abs(SellEntry.Quantity), UnmatchedQuantity);

        if (SellEntry."Trade Date" < StartDate) or (SellEntry."Trade Date" > EndDate) then
            exit;

        TotalRevenue += Revenue;
        TotalCost += MatchedCost + SellCost;
        ForeignTaxPaid := Abs(SellEntry."LCY Tax Amount");
        TotalForeignTaxPaid += ForeignTaxPaid;

        if UnmatchedQuantity > 0 then begin
            WarningCount += 1;
            InsertLine(PITCalculation, 900000 + WarningCount, "PTE PIT Calc. Line Type"::Warning, 'CHECK', '', '', StrSubstNo(MissingBuyCostTxt, InstrumentKey), 0, Format(UnmatchedQuantity), StrSubstNo(UnmatchedQuantityTxt, InstrumentKey, UnmatchedQuantity, SellEntry."Entry No.", SellEntry."Trade Date"));
        end;

        CountryCode := GetEntryCountryCode(SellEntry);
        if CountryCode = '' then begin
            WarningCount += 1;
            InsertLine(PITCalculation, 900000 + WarningCount, "PTE PIT Calc. Line Type"::Warning, 'CHECK', '', '', StrSubstNo(MissingCountryTxt, SellEntry."Entry No."), 0, SellEntry.Ticker, StrSubstNo(MissingCountryNoteTxt, SellEntry."Entry No.", SellEntry.Ticker, SellEntry.Description));
        end else
            if CountryCode <> TaxCountryCode then begin
                SellIncome := Revenue - MatchedCost - SellCost;
                AddCountryAmount(CountryIncome, CountryCode, SellIncome);
                AddCountryAmount(CountryTax, CountryCode, ForeignTaxPaid);
            end;
    end;

    local procedure AddBuyLot(var BuyLots: Dictionary of [Text, List of [Decimal]]; BuyEntry: Record "PTE Broker Entry")
    var
        LotValues: List of [Decimal];
        InstrumentKey: Text;
        Quantity: Decimal;
        UnitCost: Decimal;
        LotCost: Decimal;
    begin
        Quantity := Abs(BuyEntry.Quantity);
        if Quantity = 0 then
            exit;

        LotCost := Abs(BuyEntry."LCY Net Amount");
        if LotCost = 0 then
            LotCost := Abs(BuyEntry."LCY Gross Amount") + Abs(BuyEntry."LCY Fee Amount");
        UnitCost := LotCost / Quantity;
        InstrumentKey := GetInstrumentKey(BuyEntry);

        if BuyLots.ContainsKey(InstrumentKey) then
            LotValues := BuyLots.Get(InstrumentKey);

        LotValues.Add(Quantity);
        LotValues.Add(UnitCost);
        SetBuyLots(BuyLots, InstrumentKey, LotValues);
    end;

    local procedure ConsumeBuyLots(var BuyLots: Dictionary of [Text, List of [Decimal]]; InstrumentKey: Text; SellQuantity: Decimal; var UnmatchedQuantity: Decimal): Decimal
    var
        LotValues: List of [Decimal];
        NewLotValues: List of [Decimal];
        LotQuantity: Decimal;
        UnitCost: Decimal;
        UsedQuantity: Decimal;
        RemainingQuantity: Decimal;
        Index: Integer;
        MatchedCost: Decimal;
    begin
        RemainingQuantity := SellQuantity;
        if BuyLots.ContainsKey(InstrumentKey) then
            LotValues := BuyLots.Get(InstrumentKey);

        Index := 1;
        while (Index <= LotValues.Count()) and (RemainingQuantity > 0) do begin
            LotQuantity := LotValues.Get(Index);
            UnitCost := LotValues.Get(Index + 1);
            UsedQuantity := LotQuantity;
            if UsedQuantity > RemainingQuantity then
                UsedQuantity := RemainingQuantity;

            MatchedCost += UsedQuantity * UnitCost;
            LotQuantity -= UsedQuantity;
            RemainingQuantity -= UsedQuantity;

            if LotQuantity > 0 then begin
                NewLotValues.Add(LotQuantity);
                NewLotValues.Add(UnitCost);
            end;

            Index += 2;
        end;

        while Index <= LotValues.Count() do begin
            NewLotValues.Add(LotValues.Get(Index));
            NewLotValues.Add(LotValues.Get(Index + 1));
            Index += 2;
        end;

        SetBuyLots(BuyLots, InstrumentKey, NewLotValues);
        UnmatchedQuantity := RemainingQuantity;
        exit(MatchedCost);
    end;

    local procedure SetBuyLots(var BuyLots: Dictionary of [Text, List of [Decimal]]; InstrumentKey: Text; LotValues: List of [Decimal])
    begin
        if BuyLots.ContainsKey(InstrumentKey) then
            BuyLots.Set(InstrumentKey, LotValues)
        else
            BuyLots.Add(InstrumentKey, LotValues);
    end;

    local procedure InsertPIT38Lines(PITCalculation: Record "PTE PIT Calculation")
    begin
        InsertLine(PITCalculation, 10000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '20', 'Przychody wykazane w części D informacji PIT-8C', 0, '', NotCalculatedPIT8CTxt);
        InsertLine(PITCalculation, 20000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '21', 'Koszty uzyskania przychodów wykazane w PIT-8C', 0, '', NotCalculatedPIT8CTxt);
        InsertLine(PITCalculation, 30000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '22', 'Inne przychody', PITCalculation."PIT-38 Revenue", '', OtherIncomeTxt);
        InsertLine(PITCalculation, 40000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '23', 'Koszty uzyskania innych przychodów', PITCalculation."PIT-38 Costs", '', OtherIncomeTxt);
        InsertLine(PITCalculation, 50000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '24', 'Przychody zwolnione na podstawie art. 21 ust. 1 pkt 105a', 0, '', NotCalculatedExemptTxt);
        InsertLine(PITCalculation, 60000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '25', 'Koszty przychodów zwolnionych na podstawie art. 21 ust. 1 pkt 105a', 0, '', NotCalculatedExemptTxt);
        InsertLine(PITCalculation, 70000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '26', 'Razem przychody', PITCalculation."PIT-38 Revenue", '', 'poz. 20 + 22 - 24');
        InsertLine(PITCalculation, 80000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '27', 'Razem koszty uzyskania przychodów', PITCalculation."PIT-38 Costs", '', 'poz. 21 + 23 - 25');
        InsertLine(PITCalculation, 90000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '28', 'Dochód', PITCalculation."PIT-38 Income", '', 'max(poz. 26 - poz. 27, 0)');
        InsertLine(PITCalculation, 100000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '29', 'Strata', PITCalculation."PIT-38 Loss", '', 'max(poz. 27 - poz. 26, 0)');
        InsertLine(PITCalculation, 110000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '30', 'Straty z lat ubiegłych', PITCalculation."Prior Loss Deduction", '', 'Request page value');
        InsertLine(PITCalculation, 120000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '31', 'Podstawa obliczenia podatku', PITCalculation."Tax Base", '', 'poz. 28 - poz. 30, rounded to full PLN');
        InsertLine(PITCalculation, 130000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '32', 'Stawka podatku', PITCalculation."Tax Rate %", '%', 'Official PIT-38 rate for art. 30b');
        InsertLine(PITCalculation, 140000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '33', 'Podatek od dochodów art. 30b ust. 1', PITCalculation."Tax Before Foreign Tax", '', 'poz. 31 * poz. 32');
        InsertLine(PITCalculation, 150000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '34', 'Podatek zapłacony za granicą art. 30b ust. 5a i 5b', PITCalculation."Foreign Tax Paid", '', 'Sum from foreign sell entries');
        InsertLine(PITCalculation, 160000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '35', 'Podatek należny', PITCalculation."Securities Tax Due", '', 'max(poz. 33 - poz. 34, 0), rounded to full PLN');
        InsertLine(PITCalculation, 170000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '46', 'Zryczałtowany podatek dochodowy art. 29, art. 30 i art. 30a', 0, '', 'Not calculated by this report except foreign art. 30a below');
        InsertLine(PITCalculation, 180000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '47', 'Zryczałtowany podatek od przychodów art. 30a ust. 1 pkt 1-5 uzyskanych za granicą', PITCalculation."Flat Tax Before Foreign Tax", '', '19% from foreign dividends and interest');
        InsertLine(PITCalculation, 190000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '48', 'Podatek zapłacony za granicą art. 30a ust. 9', PITCalculation."Flat Foreign Tax Paid", '', 'Limited to poz. 47');
        InsertLine(PITCalculation, 200000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '49', 'Różnica między zryczałtowanym podatkiem a podatkiem zapłaconym za granicą', PITCalculation."Flat Tax Due", '', 'max(poz. 47 - poz. 48, 0), rounded to full PLN');
        InsertLine(PITCalculation, 210000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '50', 'Suma zaliczek przekazanych płatnikowi', 0, '', 'Not calculated by this report');
        InsertLine(PITCalculation, 220000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '51', 'Podatek do zapłaty', PITCalculation."Tax Due", '', 'poz. 35 + 45 + 46 + 49 - poz. 50');
        InsertLine(PITCalculation, 230000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '52', 'Nadpłata', 0, '', 'Not calculated by this report');
        InsertLine(PITCalculation, 240000, "PTE PIT Calc. Line Type"::PIT38, 'PIT-38', '', '72', 'PIT/ZG', PITCalculation."PIT-ZG Countries", '', 'Number of PIT/ZG attachments generated');
    end;

    local procedure InsertPITZGLines(PITCalculation: Record "PTE PIT Calculation"; CountryIncome: Dictionary of [Code[10], Decimal]; CountryTax: Dictionary of [Code[10], Decimal])
    var
        CountryCode: Code[10];
        CountryNo: Integer;
        LineNo: Integer;
    begin
        foreach CountryCode in CountryIncome.Keys() do begin
            if RoundPositive(CountryIncome.Get(CountryCode)) = 0 then
                continue;

            CountryNo += 1;
            LineNo := 300000 + (CountryNo * 10000);
            InsertLine(PITCalculation, LineNo + 1000, "PTE PIT Calc. Line Type"::PITZG, 'PIT/ZG', CountryCode, '6', 'Państwo uzyskania dochodu / przychodu', 0, CountryCode, 'Separate PIT/ZG attachment for this country');
            InsertLine(PITCalculation, LineNo + 2000, "PTE PIT Calc. Line Type"::PITZG, 'PIT/ZG', CountryCode, '29', 'Dochód, o którym mowa w art. 30b ust. 5a i 5b ustawy', RoundPositive(CountryIncome.Get(CountryCode)), '', 'Foreign income from securities sales');
            InsertLine(PITCalculation, LineNo + 3000, "PTE PIT Calc. Line Type"::PITZG, 'PIT/ZG', CountryCode, '30', 'Podatek zapłacony za granicą od dochodów z poz. 29', RoundAmount(GetCountryAmount(CountryTax, CountryCode)), '', 'Foreign tax paid from sell entries');
            InsertLine(PITCalculation, LineNo + 4000, "PTE PIT Calc. Line Type"::PITZG, 'PIT/ZG', CountryCode, '31', 'Dochód, o którym mowa w art. 30b ust. 5e i 5f ustawy', 0, '', 'Not calculated by this report');
            InsertLine(PITCalculation, LineNo + 5000, "PTE PIT Calc. Line Type"::PITZG, 'PIT/ZG', CountryCode, '32', 'Podatek zapłacony za granicą od dochodów z poz. 31', 0, '', 'Not calculated by this report');
        end;
    end;

    local procedure CountPITZGCountries(CountryIncome: Dictionary of [Code[10], Decimal]): Integer
    var
        CountryCode: Code[10];
        CountryCount: Integer;
    begin
        foreach CountryCode in CountryIncome.Keys() do
            if RoundPositive(CountryIncome.Get(CountryCode)) <> 0 then
                CountryCount += 1;

        exit(CountryCount);
    end;

    local procedure ExportLinesToExcel(PITCalculation: Record "PTE PIT Calculation"; var PITCalcLine: Record "PTE PIT Calc. Line"; SheetName: Text[250]; FileName: Text)
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
    begin
        CreateExcelBook(TempExcelBuffer, PITCalculation, PITCalcLine, SheetName);
        TempExcelBuffer.SetFriendlyFilename(FileName);
        TempExcelBuffer.OpenExcel();
    end;

    local procedure AddPIT38ToZip(PITCalculation: Record "PTE PIT Calculation"; var DataCompression: Codeunit "Data Compression")
    var
        PITCalcLine: Record "PTE PIT Calc. Line";
    begin
        PITCalcLine.SetRange("Calculation Entry No.", PITCalculation."Entry No.");
        PITCalcLine.SetRange("Line Type", PITCalcLine."Line Type"::PIT38);
        AddLinesToZip(PITCalculation, PITCalcLine, 'PIT-38', StrSubstNo(PIT38FileNameTxt, PITCalculation."Tax Year", PITCalculation."Entry No.") + ExcelFileExtensionTxt, DataCompression);
    end;

    local procedure AddPITZGToZip(PITCalculation: Record "PTE PIT Calculation"; var DataCompression: Codeunit "Data Compression")
    var
        PITCalcLine: Record "PTE PIT Calc. Line";
    begin
        PITCalcLine.SetRange("Calculation Entry No.", PITCalculation."Entry No.");
        PITCalcLine.SetRange("Line Type", PITCalcLine."Line Type"::PITZG);
        AddLinesToZip(PITCalculation, PITCalcLine, 'PIT-ZG', StrSubstNo(PITZGFileNameTxt, PITCalculation."Tax Year", PITCalculation."Entry No.") + ExcelFileExtensionTxt, DataCompression);
    end;

    local procedure AddLinesToZip(PITCalculation: Record "PTE PIT Calculation"; var PITCalcLine: Record "PTE PIT Calc. Line"; SheetName: Text[250]; EntryName: Text; var DataCompression: Codeunit "Data Compression")
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        ExcelInStream: InStream;
        ExcelOutStream: OutStream;
    begin
        CreateExcelBook(TempExcelBuffer, PITCalculation, PITCalcLine, SheetName);
        TempBlob.CreateOutStream(ExcelOutStream);
        TempExcelBuffer.SaveToStream(ExcelOutStream, true);
        TempBlob.CreateInStream(ExcelInStream);
        DataCompression.AddEntry(ExcelInStream, EntryName);
    end;

    local procedure CreateExcelBook(var TempExcelBuffer: Record "Excel Buffer" temporary; PITCalculation: Record "PTE PIT Calculation"; var PITCalcLine: Record "PTE PIT Calc. Line"; SheetName: Text[250])
    begin
        TempExcelBuffer.DeleteAll();
        AddExcelHeader(TempExcelBuffer, PITCalculation, SheetName);

        if PITCalcLine.FindSet() then
            repeat
                TempExcelBuffer.NewRow();
                TempExcelBuffer.AddColumn(PITCalcLine."Form Name", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(PITCalcLine."Country/Region Code", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(PITCalcLine."Field No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(PITCalcLine."Field Caption", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(PITCalcLine.Amount, false, '', false, false, false, '#,##0.00', TempExcelBuffer."Cell Type"::Number);
                TempExcelBuffer.AddColumn(PITCalcLine."Text Value", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(PITCalcLine.Note, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            until PITCalcLine.Next() = 0;

        TempExcelBuffer.CreateNewBook(SheetName);
        TempExcelBuffer.WriteSheet(SheetName, CompanyName(), UserId());
        TempExcelBuffer.CloseBook();
    end;

    local procedure AddExcelHeader(var TempExcelBuffer: Record "Excel Buffer" temporary; PITCalculation: Record "PTE PIT Calculation"; SheetName: Text)
    begin
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn(SheetName, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Tax Year', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(PITCalculation."Tax Year", false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Number);
        TempExcelBuffer.AddColumn('Period', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(Format(PITCalculation."Period Start Date") + ' - ' + Format(PITCalculation."Period End Date"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.NewRow();
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn('Form', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Country', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Field No.', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Field name', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Value', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Text value', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Note', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
    end;

    local procedure InsertLine(PITCalculation: Record "PTE PIT Calculation"; LineNo: Integer; LineType: Enum "PTE PIT Calc. Line Type"; FormName: Code[20]; CountryCode: Code[10]; FieldNo: Code[20]; FieldCaption: Text[250]; Amount: Decimal; TextValue: Text[250]; Note: Text[2048])
    var
        PITCalcLine: Record "PTE PIT Calc. Line";
    begin
        PITCalcLine.Init();
        PITCalcLine."Calculation Entry No." := PITCalculation."Entry No.";
        PITCalcLine."Line No." := LineNo;
        PITCalcLine."Line Type" := LineType;
        PITCalcLine."Form Name" := FormName;
        PITCalcLine."Country/Region Code" := CountryCode;
        PITCalcLine."Field No." := FieldNo;
        PITCalcLine."Field Caption" := FieldCaption;
        PITCalcLine.Amount := RoundAmount(Amount);
        PITCalcLine."Text Value" := TextValue;
        PITCalcLine.Note := Note;
        PITCalcLine.Insert();
    end;

    local procedure AddCountryAmount(var CountryAmounts: Dictionary of [Code[10], Decimal]; CountryCode: Code[10]; Amount: Decimal)
    begin
        if CountryAmounts.ContainsKey(CountryCode) then
            CountryAmounts.Set(CountryCode, CountryAmounts.Get(CountryCode) + Amount)
        else
            CountryAmounts.Add(CountryCode, Amount);
    end;

    local procedure GetCountryAmount(CountryAmounts: Dictionary of [Code[10], Decimal]; CountryCode: Code[10]): Decimal
    begin
        if CountryAmounts.ContainsKey(CountryCode) then
            exit(CountryAmounts.Get(CountryCode));

        exit(0);
    end;

    local procedure GetInstrumentKey(BrokerEntry: Record "PTE Broker Entry"): Text
    var
        InstrumentTaxCountry: Record "PTE Instrument Tax Country";
        RelatedISIN: Code[20];
    begin
        if BrokerEntry.ISIN <> '' then
            exit(BrokerEntry.ISIN);
        RelatedISIN := GetISINFromOtherEntries(BrokerEntry);
        if RelatedISIN <> '' then
            exit(RelatedISIN);
        if BrokerEntry.Ticker <> '' then begin
            if InstrumentTaxCountry.Get(BrokerEntry."Broker Code", BrokerEntry.Ticker) then
                if InstrumentTaxCountry.ISIN <> '' then
                    exit(InstrumentTaxCountry.ISIN);
            if InstrumentTaxCountry.Get('', BrokerEntry.Ticker) then
                if InstrumentTaxCountry.ISIN <> '' then
                    exit(InstrumentTaxCountry.ISIN);

            exit(BrokerEntry.Ticker);
        end;

        exit(BrokerEntry.Description);
    end;

    local procedure GetEntryCountryCode(BrokerEntry: Record "PTE Broker Entry"): Code[10]
    var
        Broker: Record "PTE Broker";
        InstrumentTaxCountry: Record "PTE Instrument Tax Country";
        CountryCode: Code[10];
    begin
        if BrokerEntry."Country/Region Code" <> '' then
            exit(BrokerEntry."Country/Region Code");
        if StrLen(BrokerEntry.ISIN) >= 2 then
            exit(CopyStr(BrokerEntry.ISIN, 1, 2));
        CountryCode := GetCountryFromRelatedISIN(BrokerEntry);
        if CountryCode <> '' then
            exit(CountryCode);
        if BrokerEntry.Ticker <> '' then begin
            if InstrumentTaxCountry.Get(BrokerEntry."Broker Code", BrokerEntry.Ticker) then
                exit(GetCountryFromInstrumentTaxCountry(InstrumentTaxCountry));
            if InstrumentTaxCountry.Get('', BrokerEntry.Ticker) then
                exit(GetCountryFromInstrumentTaxCountry(InstrumentTaxCountry));
        end;
        if (BrokerEntry."Transaction Type" = BrokerEntry."Transaction Type"::Interest) and (BrokerEntry."Instrument Type" = BrokerEntry."Instrument Type"::Cash) then
            if Broker.Get(BrokerEntry."Broker Code") then
                exit(Broker."Country/Region Code");

        exit('');
    end;

    local procedure GetCountryFromInstrumentTaxCountry(InstrumentTaxCountry: Record "PTE Instrument Tax Country"): Code[10]
    begin
        if InstrumentTaxCountry."Country/Region Code" <> '' then
            exit(InstrumentTaxCountry."Country/Region Code");
        if StrLen(InstrumentTaxCountry.ISIN) >= 2 then
            exit(CopyStr(InstrumentTaxCountry.ISIN, 1, 2));

        exit('');
    end;

    local procedure GetCountryFromRelatedISIN(BrokerEntry: Record "PTE Broker Entry"): Code[10]
    var
        RelatedISIN: Code[20];
    begin
        RelatedISIN := GetISINFromOtherEntries(BrokerEntry);
        if RelatedISIN <> '' then
            exit(CopyStr(RelatedISIN, 1, 2));

        exit('');
    end;

    local procedure GetISINFromOtherEntries(BrokerEntry: Record "PTE Broker Entry"): Code[20]
    var
        OtherBrokerEntry: Record "PTE Broker Entry";
    begin
        if BrokerEntry.Ticker = '' then
            exit('');

        OtherBrokerEntry.SetRange(Ticker, BrokerEntry.Ticker);
        OtherBrokerEntry.SetFilter(ISIN, '<>%1', '');
        if OtherBrokerEntry.FindFirst() then
            exit(OtherBrokerEntry.ISIN);

        exit('');
    end;

    local procedure RoundAmount(Amount: Decimal): Decimal
    begin
        exit(Round(Amount, 0.01, '='));
    end;

    local procedure RoundPositive(Amount: Decimal): Decimal
    begin
        if Amount < 0 then
            exit(0);

        exit(RoundAmount(Amount));
    end;

    var
        TaxYearRequiredErr: Label 'Tax year must be specified.';
        StartDateRequiredErr: Label 'Period start date must be specified.';
        EndDateRequiredErr: Label 'Period end date must be specified.';
        InvalidPeriodErr: Label 'Period start date cannot be later than period end date.';
        MissingBuyCostTxt: Label 'Missing acquisition cost for %1', Comment = '%1 = instrument key';
        MissingCountryTxt: Label 'Missing tax country for broker entry %1', Comment = '%1 = broker entry number';
        MissingCountryNoteTxt: Label 'Country cannot be determined for broker entry %1, ticker %2, description %3. Fill Country/Region Code on the broker entry or broker card. For instruments, you can also add a mapping in Instrument Tax Countries. The entry is not included in PIT/ZG country grouping until this is fixed.', Comment = '%1 = broker entry number, %2 = ticker, %3 = description';
        UnmatchedQuantityTxt: Label 'Not enough buy quantity was found for %1. Unmatched quantity: %2. Sell broker entry: %3, trade date: %4. Import the missing buy transaction or correct the broker entry before relying on the PIT result.', Comment = '%1 = instrument key, %2 = unmatched quantity, %3 = broker entry number, %4 = trade date';
        PITArchiveFileNameTxt: Label 'PIT_%1_%2.zip', Comment = '%1 = tax year, %2 = PIT calculation entry number';
        PIT38FileNameTxt: Label 'PIT-38_%1_%2', Comment = '%1 = tax year, %2 = PIT calculation entry number';
        PITZGFileNameTxt: Label 'PIT-ZG_%1_%2', Comment = '%1 = tax year, %2 = PIT calculation entry number';
        ExcelFileExtensionTxt: Label '.xlsx', Locked = true;
        ZipFileFilterTxt: Label 'Zip Files (*.zip)|*.zip', Locked = true;
        NotCalculatedPIT8CTxt: Label 'Imported broker entries are treated as other income, not PIT-8C payer data.';
        OtherIncomeTxt: Label 'Calculated from broker sell entries using FIFO acquisition costs.';
        NotCalculatedExemptTxt: Label 'Art. 21 ust. 1 pkt 105a exemption is not calculated.';
}