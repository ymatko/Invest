page 50105 "PTE Invest Activities"
{
    Caption = 'Invest Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "PTE Invest Cue";

    layout
    {
        area(content)
        {
            cuegroup(BrokerReports)
            {
                Caption = 'Broker Reports';

                field(Brokers; Rec.Brokers)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of configured brokers.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"PTE Brokers");
                    end;
                }
                field("Broker Entries"; Rec."Broker Entries")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of permanent broker entries.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"PTE Broker Entries");
                    end;
                }
                field("Broker Imports"; Rec."Broker Imports")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of broker report imports.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"PTE Broker Imports");
                    end;
                }
                field("PIT Calculations"; Rec."PIT Calculations")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of PIT calculations.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"PTE PIT Calculations");
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.EnsureExists();
    end;
}