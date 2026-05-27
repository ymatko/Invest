page 50101 "PTE Broker Card"
{
    ApplicationArea = All;
    Caption = 'Broker Card';
    PageType = Card;
    SourceTable = "PTE Broker";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker name.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the broker can be used for new imports and entries.';
                }
                field("External Account No."; Rec."External Account No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the account number or identifier used by the broker.';
                }
            }
            group(Import)
            {
                Caption = 'Import';

                field("Import Provider Code"; Rec."Import Provider Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the import provider code that will parse reports for this broker.';
                }
                field("Import Provider"; Rec."Import Provider")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the import provider that will validate and parse reports for this broker.';
                }
            }
            group(Currency)
            {
                Caption = 'Currency';

                field("Base Currency Code"; Rec."Base Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker base currency.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country or region related to the broker.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Entries)
            {
                ApplicationArea = All;
                Caption = 'Entries';
                RunObject = page "PTE Broker Entries";
                RunPageLink = "Broker Code" = field(Code);
                ToolTip = 'Open investment entries imported or created for this broker.';
            }
            action(Imports)
            {
                ApplicationArea = All;
                Caption = 'Imports';
                RunObject = page "PTE Broker Imports";
                RunPageLink = "Broker Code" = field(Code);
                ToolTip = 'Open broker report imports for this broker.';
            }
        }
    }
}