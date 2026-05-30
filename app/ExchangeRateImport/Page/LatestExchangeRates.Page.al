page 50124 "PTE Latest Exchange Rates"
{
    ApplicationArea = All;
    Caption = 'Latest Exchange Rates';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = Currency;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency code.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Currency Card", Rec);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency description.';
                }
                field("Exchange Rate Source"; Rec."PTE Exch. Rate Source")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the public source used by Invest to import exchange rates for this currency.';
                }
                field(LatestRateDate; LatestRateDate)
                {
                    ApplicationArea = All;
                    Caption = 'Latest Rate Date';
                    ToolTip = 'Specifies the latest exchange rate date available for this currency.';

                    trigger OnDrillDown()
                    begin
                        OpenExchangeRates();
                    end;
                }
                field(LatestRateAmount; LatestRateAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Latest LCY Rate';
                    DecimalPlaces = 0 : 7;
                    ToolTip = 'Specifies the latest local currency amount for one unit of this currency.';

                    trigger OnDrillDown()
                    begin
                        OpenExchangeRates();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetLatestRateValues();
    end;

    local procedure SetLatestRateValues()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Clear(LatestRateDate);
        Clear(LatestRateAmount);

        CurrencyExchangeRate.SetRange("Currency Code", Rec.Code);
        CurrencyExchangeRate.SetCurrentKey("Currency Code", "Starting Date");
        if CurrencyExchangeRate.FindLast() then begin
            LatestRateDate := CurrencyExchangeRate."Starting Date";
            LatestRateAmount := CurrencyExchangeRate."Relational Exch. Rate Amount";
        end;
    end;

    local procedure OpenExchangeRates()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", Rec.Code);
        Page.Run(Page::"Currency Exchange Rates", CurrencyExchangeRate);
    end;

    var
        LatestRateDate: Date;
        LatestRateAmount: Decimal;
}