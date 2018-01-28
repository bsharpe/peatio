class AccountError < RuntimeError; end
class Account::LockedError < AccountError; end
class Account::BalanceError < AccountError; end

class OrderError < RuntimeError; end