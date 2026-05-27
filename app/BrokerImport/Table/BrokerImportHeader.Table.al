table 50112 "PTE Broker Import Header"
{
    Caption = 'Broker Import Header';
    DataClassification = CustomerContent;
    DrillDownPageId = "PTE Broker Imports";
    LookupPageId = "PTE Broker Imports";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(10; "Broker Code"; Code[20])
        {
            Caption = 'Broker Code';
            TableRelation = "PTE Broker".Code;
        }
        field(20; "Import Provider"; Enum "PTE Broker Import Provider")
        {
            Caption = 'Import Provider';
        }
        field(30; "Source File Name"; Text[250])
        {
            Caption = 'Source File Name';
        }
        field(40; Status; Enum "PTE Broker Import Status")
        {
            Caption = 'Status';
        }
        field(50; "Report Title"; Text[100])
        {
            Caption = 'Report Title';
        }
        field(60; "Report Period"; Text[100])
        {
            Caption = 'Report Period';
        }
        field(70; "Base Currency Code"; Code[10])
        {
            Caption = 'Base Currency Code';
            TableRelation = Currency.Code;
        }
        field(80; "Schema Message"; Text[250])
        {
            Caption = 'Schema Message';
        }
        field(90; "Total Lines"; Integer)
        {
            Caption = 'Total Lines';
        }
        field(100; "Valid Lines"; Integer)
        {
            Caption = 'Valid Lines';
        }
        field(110; "Error Lines"; Integer)
        {
            Caption = 'Error Lines';
        }
        field(120; "Imported Lines"; Integer)
        {
            Caption = 'Imported Lines';
        }
        field(130; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(140; "Created By"; Code[50])
        {
            Caption = 'Created By';
        }
        field(150; "Imported At"; DateTime)
        {
            Caption = 'Imported At';
        }
        field(160; "Imported By"; Code[50])
        {
            Caption = 'Imported By';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(BrokerStatus; "Broker Code", Status)
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