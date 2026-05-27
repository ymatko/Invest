page 50100 "PTE Invest Setup"
{
    ApplicationArea = All;
    Caption = 'Invest Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "PTE Invest Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("LCY Currency Code"; Rec."LCY Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the local currency used for investment and tax calculations.';
                }
                field("Default Broker Code"; Rec."Default Broker Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker used by default when creating broker entries.';
                }
                field("Default Tax Year"; Rec."Default Tax Year")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the tax year suggested for PIT calculations.';
                }
                field("Tax Country/Region Code"; Rec."Tax Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country or region used as the main tax residence for calculations.';
                }
            }
            group(Calculation)
            {
                Caption = 'Calculation';

                field("Exchange Rate Date Basis"; Rec."Exchange Rate Date Basis")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether currency exchange rates are selected by trade date or settlement date.';
                }
                field("Amount Rounding Precision"; Rec."Amount Rounding Precision")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount rounding precision used in tax calculations.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CurrencyExchangeRates)
            {
                ApplicationArea = All;
                Caption = 'Currency Exchange Rates';
                RunObject = page "Currency Exchange Rates";
                ToolTip = 'Open standard Business Central currency exchange rates.';
            }
            action(ImportFXRates)
            {
                ApplicationArea = All;
                Caption = 'Import Exchange Rates';
                RunObject = report "PTE Import Exchange Rates";
                ToolTip = 'Import exchange rates by using the source selected on currency cards.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.EnsureExists();
    end;
}