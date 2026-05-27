table 50102 "PTE Broker Entry"
{
    Caption = 'Broker Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "PTE Broker Entries";
    LookupPageId = "PTE Broker Entries";

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

            trigger OnValidate()
            var
                Broker: Record "PTE Broker";
            begin
                if "Broker Code" = '' then
                    exit;

                if not Broker.Get("Broker Code") then
                    exit;

                if "Currency Code" = '' then
                    "Currency Code" := Broker."Base Currency Code";
            end;
        }
        field(20; "External Entry ID"; Text[100])
        {
            Caption = 'External Entry ID';
        }
        field(25; "Broker Account No."; Text[50])
        {
            Caption = 'Broker Account No.';
        }
        field(30; "Transaction Type"; Option)
        {
            Caption = 'Transaction Type';
            OptionCaption = 'Buy,Sell,Dividend,Interest,Fee,Tax,Deposit,Withdrawal,Other';
            OptionMembers = Buy,Sell,Dividend,Interest,Fee,Tax,Deposit,Withdrawal,Other;
        }
        field(35; "Source Transaction Type"; Text[50])
        {
            Caption = 'Source Transaction Type';
        }
        field(40; "Instrument Type"; Option)
        {
            Caption = 'Instrument Type';
            OptionCaption = 'Stock,ETF,Bond,Fund,Cash,Other';
            OptionMembers = Stock,ETF,Bond,Fund,Cash,Other;
        }
        field(50; "Trade Date"; Date)
        {
            Caption = 'Trade Date';

            trigger OnValidate()
            begin
                if "Trade Date" <> 0D then
                    "Tax Year" := Date2DMY("Trade Date", 3);
            end;
        }
        field(60; "Settlement Date"; Date)
        {
            Caption = 'Settlement Date';
        }
        field(70; "Tax Year"; Integer)
        {
            Caption = 'Tax Year';
        }
        field(80; ISIN; Code[20])
        {
            Caption = 'ISIN';
        }
        field(90; Ticker; Code[30])
        {
            Caption = 'Ticker';
        }
        field(100; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(110; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region".Code;
        }
        field(120; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(130; Price; Decimal)
        {
            Caption = 'Price';
        }
        field(135; "Price Currency Code"; Code[10])
        {
            Caption = 'Price Currency Code';
            TableRelation = Currency.Code;
        }
        field(140; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(150; "Gross Amount"; Decimal)
        {
            Caption = 'Gross Amount';
        }
        field(160; "Fee Amount"; Decimal)
        {
            Caption = 'Fee Amount';
        }
        field(170; "Tax Amount"; Decimal)
        {
            Caption = 'Tax Amount';
        }
        field(180; "Net Amount"; Decimal)
        {
            Caption = 'Net Amount';
        }
        field(190; "Exchange Rate"; Decimal)
        {
            Caption = 'Exchange Rate';
        }
        field(200; "LCY Gross Amount"; Decimal)
        {
            Caption = 'LCY Gross Amount';
        }
        field(210; "LCY Fee Amount"; Decimal)
        {
            Caption = 'LCY Fee Amount';
        }
        field(220; "LCY Tax Amount"; Decimal)
        {
            Caption = 'LCY Tax Amount';
        }
        field(230; "LCY Net Amount"; Decimal)
        {
            Caption = 'LCY Net Amount';
        }
        field(240; "Import Batch No."; Code[20])
        {
            Caption = 'Import Batch No.';
        }
        field(245; "Broker Import Entry No."; Integer)
        {
            Caption = 'Broker Import Entry No.';
            TableRelation = "PTE Broker Import Header"."Entry No.";
        }
        field(250; "Source File Name"; Text[250])
        {
            Caption = 'Source File Name';
        }
        field(260; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(270; "Duplicate Check Key"; Text[250])
        {
            Caption = 'Duplicate Check Key';
        }
        field(280; "Imported At"; DateTime)
        {
            Caption = 'Imported At';
        }
        field(290; "Imported By"; Code[50])
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
        key(BrokerDate; "Broker Code", "Trade Date")
        {
        }
        key(TradeDate; "Trade Date")
        {
        }
        key(TaxYearCountry; "Tax Year", "Country/Region Code")
        {
        }
        key(DuplicateCheck; "Duplicate Check Key")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Imported At" = 0DT then
            "Imported At" := CurrentDateTime;

        if "Imported By" = '' then
            "Imported By" := CopyStr(UserId(), 1, MaxStrLen("Imported By"));
    end;
}