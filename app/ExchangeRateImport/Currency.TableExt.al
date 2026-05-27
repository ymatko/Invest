tableextension 50100 "PTE Currency" extends Currency
{
    fields
    {
        field(50100; "PTE Exch. Rate Source"; Enum "PTE Exch. Rate Source")
        {
            Caption = 'Exchange Rate Source';
            DataClassification = CustomerContent;
        }
    }
}
