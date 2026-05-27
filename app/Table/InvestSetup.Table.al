table 50100 "PTE Invest Setup"
{
    Caption = 'Invest Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "LCY Currency Code"; Code[10])
        {
            Caption = 'LCY Currency Code';
            TableRelation = Currency.Code;
        }
        field(20; "Default Broker Code"; Code[20])
        {
            Caption = 'Default Broker Code';
            TableRelation = "PTE Broker".Code;
        }
        field(30; "Default Tax Year"; Integer)
        {
            Caption = 'Default Tax Year';
        }
        field(40; "Exchange Rate Date Basis"; Option)
        {
            Caption = 'Exchange Rate Date Basis';
            OptionCaption = 'Trade Date,Settlement Date';
            OptionMembers = TradeDate,SettlementDate;
        }
        field(60; "Amount Rounding Precision"; Decimal)
        {
            Caption = 'Amount Rounding Precision';
        }
        field(70; "Tax Country/Region Code"; Code[10])
        {
            Caption = 'Tax Country/Region Code';
            TableRelation = "Country/Region".Code;
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