pageextension 50100 "PTE Currency Card" extends "Currency Card"
{
    layout
    {
        addlast(Content)
        {
            group(PTEExchangeRateImport)
            {
                Caption = 'Exchange Rate Import';

                field("PTE Exch. Rate Source"; Rec."PTE Exch. Rate Source")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the public source used by Invest to import exchange rates for this currency.';
                }
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(PTEImportExchangeRates)
            {
                ApplicationArea = All;
                Caption = 'Import Exchange Rates';
                ToolTip = 'Import exchange rates for this currency by using the selected Invest exchange rate source.';

                trigger OnAction()
                var
                    ImportExchangeRates: Report "PTE Import Exchange Rates";
                begin
                    ImportExchangeRates.SetCurrencyCode(Rec.Code);
                    ImportExchangeRates.RunModal();
                end;
            }
        }
    }
}
