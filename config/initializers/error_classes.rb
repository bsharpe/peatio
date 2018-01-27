class AccountError < RuntimeError; end
class LockedError < AccountError; end
class BalanceError < AccountError; end

class OrderError < RuntimeError; end