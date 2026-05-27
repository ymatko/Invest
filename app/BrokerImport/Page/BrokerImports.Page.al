page 50112 "PTE Broker Imports"
{
    ApplicationArea = All;
    Caption = 'Broker Imports';
    CardPageId = "PTE Broker Import";
    PageType = List;
    SourceTable = "PTE Broker Import Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the import entry number.';
                }
                field("Broker Code"; Rec."Broker Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the broker code.';
                }
                field("Import Provider"; Rec."Import Provider")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the import provider used for this broker report.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the import status.';
                }
                field("Source File Name"; Rec."Source File Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the imported source file name.';
                }
                field("Base Currency Code"; Rec."Base Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base currency read from the broker report.';
                }
                field("Total Lines"; Rec."Total Lines")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of parsed transaction lines.';
                }
                field("Valid Lines"; Rec."Valid Lines")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of valid transaction lines.';
                }
                field("Error Lines"; Rec."Error Lines")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of transaction lines with validation errors.';
                }
                field("Imported Lines"; Rec."Imported Lines")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of lines imported to broker entries.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the import preview was created.';
                }
            }
        }
    }
}