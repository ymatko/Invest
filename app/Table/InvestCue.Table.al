table 50103 "PTE Invest Cue"
{
    Caption = 'Invest Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; Brokers; Integer)
        {
            CalcFormula = count("PTE Broker");
            Caption = 'Brokers';
            FieldClass = FlowField;
        }
        field(20; "Broker Entries"; Integer)
        {
            CalcFormula = count("PTE Broker Entry");
            Caption = 'Broker Entries';
            FieldClass = FlowField;
        }
        field(30; "Broker Imports"; Integer)
        {
            CalcFormula = count("PTE Broker Import Header");
            Caption = 'Broker Imports';
            FieldClass = FlowField;
        }
        field(40; "PIT Calculations"; Integer)
        {
            CalcFormula = count("PTE PIT Calculation");
            Caption = 'PIT Calculations';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure EnsureExists()
    begin
        if Get() then
            exit;

        Init();
        Insert();
    end;
}