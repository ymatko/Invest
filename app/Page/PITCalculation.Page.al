page 50121 "PTE PIT Calculation"
{
    ApplicationArea = All;
    Caption = 'PIT Calculation';
    PageType = Document;
    SourceTable = "PTE PIT Calculation";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the PIT calculation entry number.';
                }
                field("Tax Year"; Rec."Tax Year")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the tax year.';
                }
                field("Period Start Date"; Rec."Period Start Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the period start date.';
                }
                field("Period End Date"; Rec."Period End Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the period end date.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the calculation status.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies when the calculation was created.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies who created the calculation.';
                }
            }
            group(Amounts)
            {
                Caption = 'Amounts';

                field("PIT-38 Revenue"; Rec."PIT-38 Revenue")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the PIT-38 revenue.';
                }
                field("PIT-38 Costs"; Rec."PIT-38 Costs")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the PIT-38 costs.';
                }
                field("PIT-38 Income"; Rec."PIT-38 Income")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the PIT-38 income.';
                }
                field("PIT-38 Loss"; Rec."PIT-38 Loss")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the PIT-38 loss.';
                }
                field("Tax Base"; Rec."Tax Base")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the tax base.';
                }
                field("Tax Before Foreign Tax"; Rec."Tax Before Foreign Tax")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the tax before foreign tax deduction.';
                }
                field("Foreign Tax Paid"; Rec."Foreign Tax Paid")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies foreign tax paid.';
                }
                field("Securities Tax Due"; Rec."Securities Tax Due")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the tax due from securities sales.';
                }
                field("Flat Tax Before Foreign Tax"; Rec."Flat Tax Before Foreign Tax")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the flat tax before foreign tax deduction.';
                }
                field("Flat Foreign Tax Paid"; Rec."Flat Foreign Tax Paid")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies foreign withholding tax paid on dividends and interest.';
                }
                field("Flat Tax Due"; Rec."Flat Tax Due")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the flat tax due from foreign dividends and interest.';
                }
                field("Tax Due"; Rec."Tax Due")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the total tax due.';
                }
            }
            part(Lines; "PTE PIT Calc. Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Calculation Entry No." = field("Entry No.");
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
                ToolTip = 'Export PIT-38 to Excel.';

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
                ToolTip = 'Export PIT/ZG to Excel when required.';

                trigger OnAction()
                var
                    PITCalcManagement: Codeunit "PTE PIT Calc. Mgmt.";
                begin
                    PITCalcManagement.ExportPITZG(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ExportPITArchive_Promoted; ExportPITArchive)
                {
                }
                actionref(ExportPIT38_Promoted; ExportPIT38)
                {
                }
                actionref(ExportPITZG_Promoted; ExportPITZG)
                {
                }
            }
        }
    }
}