page 50120 "PTE PIT Calculations"
{
    ApplicationArea = All;
    Caption = 'PIT Calculations';
    CardPageId = "PTE PIT Calculation";
    PageType = List;
    SourceTable = "PTE PIT Calculation";
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
                    ToolTip = 'Specifies the PIT calculation entry number.';
                }
                field("Tax Year"; Rec."Tax Year")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the tax year.';
                }
                field("Period Start Date"; Rec."Period Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the period start date.';
                }
                field("Period End Date"; Rec."Period End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the period end date.';
                }
                field("PIT-38 Income"; Rec."PIT-38 Income")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the PIT-38 income.';
                }
                field("PIT-38 Loss"; Rec."PIT-38 Loss")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the PIT-38 loss.';
                }
                field("Tax Due"; Rec."Tax Due")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the calculated tax due.';
                }
                field("PIT-ZG Required"; Rec."PIT-ZG Required")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether PIT/ZG attachments are required.';
                }
                field("Warning Count"; Rec."Warning Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of calculation warnings.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportPITArchive)
            {
                ApplicationArea = All;
                Caption = 'Export PIT Archive';
                ToolTip = 'Export PIT-38 and PIT/ZG Excel files in a ZIP archive.';

                trigger OnAction()
                var
                    PITCalcManagement: Codeunit "PTE PIT Calc. Mgmt.";
                begin
                    PITCalcManagement.ExportPITArchive(Rec);
                end;
            }
            action(ExportPIT38)
            {
                ApplicationArea = All;
                Caption = 'Export PIT-38';
                ToolTip = 'Export the selected PIT-38 calculation to Excel.';

                trigger OnAction()
                var
                    PITCalcManagement: Codeunit "PTE PIT Calc. Mgmt.";
                begin
                    PITCalcManagement.ExportPIT38(Rec);
                end;
            }
            action(ExportPITZG)
            {
                ApplicationArea = All;
                Caption = 'Export PIT/ZG';
                ToolTip = 'Export the selected PIT/ZG calculation to Excel.';

                trigger OnAction()
                var
                    PITCalcManagement: Codeunit "PTE PIT Calc. Mgmt.";
                begin
                    PITCalcManagement.ExportPITZG(Rec);
                end;
            }
        }
    }
}