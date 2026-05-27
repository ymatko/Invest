table 50122 "PTE Instrument Tax Country"
{
    Caption = 'Instrument Tax Country';
    DataClassification = CustomerContent;
    DrillDownPageId = "PTE Instrument Tax Countries";
    LookupPageId = "PTE Instrument Tax Countries";

    fields
    {
        field(1; "Broker Code"; Code[20])
        {
            Caption = 'Broker Code';
            TableRelation = "PTE Broker".Code;
        }
        field(2; Ticker; Code[30])
        {
            Caption = 'Ticker';
            NotBlank = true;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(20; ISIN; Code[20])
        {
            Caption = 'ISIN';
        }
        field(30; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region".Code;
        }
    }

    keys
    {
        key(PK; "Broker Code", Ticker)
        {
            Clustered = true;
        }
        key(Country; "Country/Region Code")
        {
        }
    }
}