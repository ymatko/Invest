report 50101 "PTE Calculate PIT"
{
    ApplicationArea = All;
    Caption = 'Calculate PIT';
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

                    field(TaxYearControl; TaxYear)
                    {
                        ApplicationArea = All;
                        Caption = 'Tax Year';
                        ToolTip = 'Specifies the tax year for PIT-38 and PIT/ZG calculation.';
                    }
                    field(StartDateControl; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Period Start Date';
                        ToolTip = 'Specifies the first date included in the PIT calculation.';
                    }
                    field(EndDateControl; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Period End Date';
                        ToolTip = 'Specifies the last date included in the PIT calculation.';
                    }
                    field(PriorLossDeductionControl; PriorLossDeduction)
                    {
                        ApplicationArea = All;
                        Caption = 'Prior Loss Deduction';
                        ToolTip = 'Specifies prior years loss to put into PIT-38 field 30.';
                    }
                    field(ExportExcelControl; ExportExcel)
                    {
                        ApplicationArea = All;
                        Caption = 'Export Archive';
                        ToolTip = 'Specifies whether a ZIP archive with PIT Excel files is exported after the calculation.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        var
            InvestSetup: Record "PTE Invest Setup";
        begin
            if TaxYear = 0 then begin
                if InvestSetup.Get() then
                    TaxYear := InvestSetup."Default Tax Year";
                if TaxYear = 0 then
                    TaxYear := Date2DMY(Today(), 3) - 1;
            end;
            if StartDate = 0D then
                StartDate := DMY2Date(1, 1, TaxYear);
            if EndDate = 0D then
                EndDate := DMY2Date(31, 12, TaxYear);
            ExportExcel := true;
        end;
    }

    trigger OnPreReport()
    begin
        PITCalcManagement.CreateCalculation(TaxYear, StartDate, EndDate, PriorLossDeduction, PITCalculation);
        if ExportExcel then
            PITCalcManagement.ExportPITArchive(PITCalculation);
    end;

    trigger OnPostReport()
    begin
        if PITCalculation."Entry No." <> 0 then
            Page.Run(Page::"PTE PIT Calculation", PITCalculation);
    end;

    var
        PITCalculation: Record "PTE PIT Calculation";
        PITCalcManagement: Codeunit "PTE PIT Calc. Mgmt.";
        TaxYear: Integer;
        StartDate: Date;
        EndDate: Date;
        PriorLossDeduction: Decimal;
        ExportExcel: Boolean;
}