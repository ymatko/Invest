report 50102 "PTE Import Exchange Rates"
{
    ApplicationArea = All;
    Caption = 'Import Exchange Rates';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    requestpage
    {
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(StartDateControl; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the first date for exchange rate import.';
                    }
                    field(EndDateControl; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the last date for exchange rate import.';
                    }
                    field(CurrencyCodeFilterControl; CurrencyCodeFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Currency Code Filter';
                        ToolTip = 'Specifies the currency code filter. Leave blank to import all currencies that have an exchange rate source.';
                    }
                    field(ReplaceExistingControl; ReplaceExisting)
                    {
                        ApplicationArea = All;
                        Caption = 'Replace Existing Rates';
                        ToolTip = 'Specifies whether existing exchange rates on the same date are replaced.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            if StartDate = 0D then
                StartDate := DMY2Date(1, 1, Date2DMY(Today(), 3));
            if EndDate = 0D then
                EndDate := Today();
            ReplaceExisting := true;
        end;
    }

    trigger OnPreReport()
    var
        ExchangeRateImport: Codeunit "PTE Exch. Rate Import Mgmt.";
        ImportedCount: Integer;
    begin
        ImportedCount := ExchangeRateImport.ImportExchangeRates(StartDate, EndDate, CurrencyCodeFilter, ReplaceExisting);
        Message(ImportFinishedMsg, ImportedCount);
    end;

    procedure SetCurrencyCode(CurrencyCode: Code[10])
    begin
        CurrencyCodeFilter := CurrencyCode;
    end;

    var
        StartDate: Date;
        EndDate: Date;
        CurrencyCodeFilter: Text[250];
        ReplaceExisting: Boolean;
        ImportFinishedMsg: Label '%1 exchange rate entries were imported or updated.', Comment = '%1 = number of exchange rate records';
}
