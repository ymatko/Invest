page 50113 "PTE Broker Import"
{
    ApplicationArea = All;
    Caption = 'Broker Import';
    PageType = Document;
    SourceTable = "PTE Broker Import Header";

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
                    ToolTip = 'Specifies the import entry number.';
                }
                field("Broker Code"; Rec."Broker Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the broker code.';
                }
                field("Import Provider"; Rec."Import Provider")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the import provider used for this broker report.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the import status.';
                }
                field("Source File Name"; Rec."Source File Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the imported source file name.';
                }
                field("Schema Message"; Rec."Schema Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies a schema validation message for the imported broker report.';
                }
            }
            group(Report)
            {
                Caption = 'Report';

                field("Report Title"; Rec."Report Title")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the report title read from the source file.';
                }
                field("Report Period"; Rec."Report Period")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the report period read from the source file.';
                }
                field("Base Currency Code"; Rec."Base Currency Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the base currency read from the source file.';
                }
            }
            group(Totals)
            {
                Caption = 'Totals';

                field("Total Lines"; Rec."Total Lines")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number of parsed transaction lines.';
                }
                field("Valid Lines"; Rec."Valid Lines")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number of valid transaction lines.';
                }
                field("Error Lines"; Rec."Error Lines")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number of transaction lines with validation errors.';
                }
                field("Imported Lines"; Rec."Imported Lines")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number of lines imported to broker entries.';
                }
            }
            part(Lines; "PTE Broker Import Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Import Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Revalidate)
            {
                ApplicationArea = All;
                Caption = 'Revalidate';
                Image = Check;
                ToolTip = 'Validate the import preview lines again.';

                trigger OnAction()
                var
                    BrokerImportManagement: Codeunit "PTE Broker Import Management";
                begin
                    BrokerImportManagement.ValidateImport(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ImportValidLines)
            {
                ApplicationArea = All;
                Caption = 'Import Valid Lines';
                Image = Import;
                ToolTip = 'Create permanent broker entries from the validated import preview.';

                trigger OnAction()
                var
                    BrokerImportManagement: Codeunit "PTE Broker Import Management";
                begin
                    BrokerImportManagement.ImportValidLines(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Revalidate_Promoted; Revalidate)
                {
                }
                actionref(ImportValidLines_Promoted; ImportValidLines)
                {
                }
            }
        }
    }
}