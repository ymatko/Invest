report 50100 "PTE Import Broker Report"
{
    ApplicationArea = All;
    Caption = 'Import Broker Report';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    requestpage
    {
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(BrokerCodeControl; SelectedBrokerCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Broker Code';
                        TableRelation = "PTE Broker".Code where(Active = const(true));
                        ToolTip = 'Specifies the broker whose report will be imported.';
                    }
                    field(ImportAfterValidationControl; RunImportAfterValidation)
                    {
                        ApplicationArea = All;
                        Caption = 'Import after validation';
                        ToolTip = 'Specifies whether valid preview lines are imported to permanent broker entries if there are no validation errors.';
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    var
        Broker: Record "PTE Broker";
        BrokerReportProvider: Interface "PTE Broker Report Provider";
        SourceInStream: InStream;
        SourceFileName: Text;
    begin
        Broker.Get(SelectedBrokerCode);
        Broker.TestField(Active, true);
        Broker.TestField("Import Provider");

        if not UploadIntoStream(UploadBrokerReportTxt, '', CsvFileFilterTxt, SourceFileName, SourceInStream) then
            Error(NoFileSelectedErr);

        BrokerReportProvider := Broker."Import Provider";
        BrokerReportProvider.Import(Broker, SourceFileName, SourceInStream, ImportHeader);

        BrokerImportManagement.ValidateImport(ImportHeader);
        if RunImportAfterValidation and (ImportHeader.Status <> ImportHeader.Status::Failed) then
            BrokerImportManagement.ImportValidLines(ImportHeader);
    end;

    trigger OnPostReport()
    begin
        if ImportHeader."Entry No." <> 0 then
            Page.Run(Page::"PTE Broker Import", ImportHeader);
    end;

    var
        ImportHeader: Record "PTE Broker Import Header";
        BrokerImportManagement: Codeunit "PTE Broker Import Management";
        SelectedBrokerCode: Code[20];
        RunImportAfterValidation: Boolean;
        UploadBrokerReportTxt: Label 'Select broker report';
        CsvFileFilterTxt: Label 'CSV files (*.csv)|*.csv|All files (*.*)|*.*', Locked = true;
        NoFileSelectedErr: Label 'No broker report file was selected.';
}