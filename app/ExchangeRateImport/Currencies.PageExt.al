pageextension 50101 "PTE Currencies" extends Currencies
{
    layout
    {
        addlast(Control1)
        {
            field("PTE Exch. Rate Source"; Rec."PTE Exch. Rate Source")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the public source used by Invest to import exchange rates for this currency.';
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
                ToolTip = 'Import exchange rates for the selected currency by using the selected Invest exchange rate source.';

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
