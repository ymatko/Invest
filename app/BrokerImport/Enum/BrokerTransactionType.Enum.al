enum 50104 "PTE Broker Transaction Type"
{
    Caption = 'Broker Transaction Type', Locked = true;

    value(0; Buy)
    {
        Caption = 'Buy', Locked = true;
    }
    value(1; Sell)
    {
        Caption = 'Sell', Locked = true;
    }
    value(2; Dividend)
    {
        Caption = 'Dividend', Locked = true;
    }
    value(3; Interest)
    {
        Caption = 'Interest', Locked = true;
    }
    value(4; Fee)
    {
        Caption = 'Fee', Locked = true;
    }
    value(5; Tax)
    {
        Caption = 'Tax', Locked = true;
    }
    value(6; Deposit)
    {
        Caption = 'Deposit', Locked = true;
    }
    value(7; Withdrawal)
    {
        Caption = 'Withdrawal', Locked = true;
    }
    value(8; Other)
    {
        Caption = 'Other', Locked = true;
    }
}