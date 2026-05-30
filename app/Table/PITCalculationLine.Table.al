table 50121 "PTE PIT Calc. Line"
{
    Caption = 'PIT Calculation Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Calculation Entry No."; Integer)
        {
            Caption = 'Calculation Entry No.';
            TableRelation = "PTE PIT Calculation"."Entry No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Line Type"; Enum "PTE PIT Calc. Line Type")
        {
            Caption = 'Line Type';
        }
        field(20; "Form Name"; Code[20])
        {
            Caption = 'Form Name';
        }
        field(30; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region".Code;
        }
        field(40; "Field No."; Code[20])
        {
            Caption = 'Field No.';
        }
        field(50; "Field Caption"; Text[250])
        {
            Caption = 'Field Caption';
        }
        field(60; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(70; "Text Value"; Text[250])
        {
            Caption = 'Text Value';
        }
        field(80; Note; Text[2048])
        {
            Caption = 'Note';
        }
    }

    keys
    {
        key(PK; "Calculation Entry No.", "Line No.")
        {
            Clustered = true;
        }
        key(FormCountry; "Calculation Entry No.", "Line Type", "Country/Region Code")
        {
        }
    }
}