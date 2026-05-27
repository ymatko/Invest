table 50101 "PTE Broker"
{
    Caption = 'Broker';
    DataClassification = CustomerContent;
    DrillDownPageId = "PTE Brokers";
    LookupPageId = "PTE Brokers";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(10; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(20; "Base Currency Code"; Code[10])
        {
            Caption = 'Base Currency Code';
            TableRelation = Currency.Code;
        }
        field(30; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region".Code;
        }
        field(40; "Import Provider Code"; Code[30])
        {
            Caption = 'Import Provider Code';
        }
        field(45; "Import Provider"; Enum "PTE Broker Import Provider")
        {
            Caption = 'Import Provider';

            trigger OnValidate()
            begin
                case "Import Provider" of
                    "Import Provider"::" ":
                        "Import Provider Code" := '';
                    "Import Provider"::InteractiveBrokers:
                        "Import Provider Code" := 'IBKR';
                    "Import Provider"::Trading212:
                        "Import Provider Code" := 'T212';
                end;
            end;
        }
        field(60; Active; Boolean)
        {
            Caption = 'Active';
            InitValue = true;
        }
        field(70; "External Account No."; Text[50])
        {
            Caption = 'External Account No.';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
        key(Name; Name)
        {
        }
    }
}