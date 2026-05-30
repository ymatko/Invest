page 50102 "PTE Brokers"
{
    ApplicationArea = All;
    Caption = 'Brokers';
    CardPageId = "PTE Broker Card";
    PageType = List;
    SourceTable = "PTE Broker";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
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
                field("Base Currency Code"; Rec."Base Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker base currency.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker country or region used for broker-paid cash interest when no instrument country is available.';
                }
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
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the broker can be used for new imports and entries.';
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
                ToolTip = 'Open investment entries imported or created for the selected broker.';
            }
            action(Imports)
            {
                ApplicationArea = All;
                Caption = 'Imports';
                RunObject = page "PTE Broker Imports";
                RunPageLink = "Broker Code" = field(Code);
                ToolTip = 'Open broker report imports for the selected broker.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Entries_Promoted; Entries)
                {
                }
                actionref(Imports_Promoted; Imports)
                {
                }
            }
        }
    }
}