enum 50101 "PTE Exch. Rate Date Basis"
{
    Caption = 'Exchange Rate Date Basis', Locked = true;

    value(0; TradeDate)
    {
        Caption = 'Trade Date', Locked = true;
    }
    value(1; SettlementDate)
    {
        Caption = 'Settlement Date', Locked = true;
    }
}