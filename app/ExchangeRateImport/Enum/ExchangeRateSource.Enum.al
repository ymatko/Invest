enum 50100 "PTE Exch. Rate Source"
{
    Caption = 'Exchange Rate Source', Locked = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(10; ECB)
    {
        Caption = 'European Central Bank', Locked = true;
    }
    value(20; NBU)
    {
        Caption = 'National Bank of Ukraine', Locked = true;
    }
    value(30; NBP)
    {
        Caption = 'National Bank of Poland', Locked = true;
    }
}
