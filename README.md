Smart Contract: Deposit and Loan System
Overview
This smart contract enables users to deposit savings and borrow money against their deposits. The system supports flexible loan repayment, enforces borrowing limits based on deposit amounts, and includes penalties for late payments.

Features
1. Deposit Savings
Users can deposit a specific amount of funds and earn interest over time.
Each deposit is recorded with its amount and interest rate.
2. Borrow Against Deposits
Users can borrow up to 80% of their deposit amount.
Loan interest rates vary based on the loan amount:
≤ 50% of max loan: Base interest rate + 2%.
> 50% of max loan: Base interest rate + 3%.
Loan duration must be selected from pre-approved options.
Each loan is tied to a specific deposit, which cannot be reused for another loan.
3. Repay Loans
Users can repay loans partially or fully.
Loan repayments reduce the remaining balance of the loan.
Late repayments incur a penalty of 100,000 units added to the remaining loan balance.
4. Late Payment Penalty
If a loan is not fully repaid by its due date, a one-time penalty of 100,000 units is added.
The system ensures penalties are applied only once per loan.
Smart Contract Functions
borrow(uint depositIndex, uint loanAmount, uint _duration)
Purpose: Initiate a loan based on a user's deposit.
Validations:
Deposit must not already be used for a loan.
Loan amount must not exceed 80% of the deposit.
Loan duration must match valid options.
Inputs:
depositIndex: The index of the user's deposit.
loanAmount: The amount to borrow.
_duration: Duration of the loan in months.
Emits:
LoanTaken event upon successful loan creation.
repayLoan(uint loanIndex, uint repaymentAmount)
Purpose: Repay a loan, either partially or fully.
Validations:
Late penalties are applied if the repayment is overdue.
Ensures repayment does not exceed the remaining loan balance.
Inputs:
loanIndex: The index of the user's loan.
repaymentAmount: Amount to repay.
Emits:
LoanRepaid event upon successful repayment.
LatePenaltyAdded event if penalties are applied.
