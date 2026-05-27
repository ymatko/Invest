table 50120 "PTE PIT Calculation"
{
    Caption = 'PIT Calculation';
    DataClassification = CustomerContent;
    DrillDownPageId = "PTE PIT Calculations";
    LookupPageId = "PTE PIT Calculations";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(10; "Tax Year"; Integer)
        {
            Caption = 'Tax Year';
        }
        field(20; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
        }
        field(30; "Period End Date"; Date)
        {
            Caption = 'Period End Date';
        }
        field(40; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Created,Calculated';
            OptionMembers = Created,Calculated;
        }
        field(50; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(60; "Created By"; Code[50])
        {
            Caption = 'Created By';
        }
        field(70; "Source Entries"; Integer)
        {
            Caption = 'Source Entries';
        }
        field(80; "PIT-ZG Required"; Boolean)
        {
            Caption = 'PIT-ZG Required';
        }
        field(90; "PIT-ZG Countries"; Integer)
        {
            Caption = 'PIT-ZG Countries';
        }
        field(100; "Prior Loss Deduction"; Decimal)
        {
            Caption = 'Prior Loss Deduction';
        }
        field(110; "PIT-38 Revenue"; Decimal)
        {
            Caption = 'PIT-38 Revenue';
        }
        field(120; "PIT-38 Costs"; Decimal)
        {
            Caption = 'PIT-38 Costs';
        }
        field(130; "PIT-38 Income"; Decimal)
        {
            Caption = 'PIT-38 Income';
        }
        field(140; "PIT-38 Loss"; Decimal)
        {
            Caption = 'PIT-38 Loss';
        }
        field(150; "Tax Base"; Decimal)
        {
            Caption = 'Tax Base';
        }
        field(160; "Tax Rate %"; Decimal)
        {
            Caption = 'Tax Rate %';
        }
        field(170; "Tax Before Foreign Tax"; Decimal)
        {
            Caption = 'Tax Before Foreign Tax';
        }
        field(180; "Foreign Tax Paid"; Decimal)
        {
            Caption = 'Foreign Tax Paid';
        }
        field(185; "Securities Tax Due"; Decimal)
        {
            Caption = 'Securities Tax Due';
        }
        field(186; "Flat Tax Before Foreign Tax"; Decimal)
        {
            Caption = 'Flat Tax Before Foreign Tax';
        }
        field(187; "Flat Foreign Tax Paid"; Decimal)
        {
            Caption = 'Flat Foreign Tax Paid';
        }
        field(188; "Flat Tax Due"; Decimal)
        {
            Caption = 'Flat Tax Due';
        }
        field(190; "Tax Due"; Decimal)
        {
            Caption = 'Tax Due';
        }
        field(200; "Warning Count"; Integer)
        {
            Caption = 'Warning Count';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(TaxYear; "Tax Year", "Period Start Date", "Period End Date")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime;

        if "Created By" = '' then
            "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
    end;
}