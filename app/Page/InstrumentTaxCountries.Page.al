page 50123 "PTE Instrument Tax Countries"
{
    ApplicationArea = All;
    Caption = 'Instrument Tax Countries';
    PageType = List;
    SourceTable = "PTE Instrument Tax Country";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Broker Code"; Rec."Broker Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker code. Leave blank for a generic ticker mapping.';
                }
                field(Ticker; Rec.Ticker)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ticker from broker entries.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the instrument description.';
                }
                field(ISIN; Rec.ISIN)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ISIN if it is known.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country or region used by PIT/ZG.';
                }
            }
        }
    }
}