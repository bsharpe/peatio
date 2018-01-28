class AccountError < RuntimeError; end
class Account::LockedError < AccountError; end
class Account::BalanceError < AccountError; end

class OrderError < RuntimeError; end

module OrderBook
  class NoTop < RuntimeError; end
  class TooShallow < RuntimeError; end
  class VolumeTooLarge < RuntimeError; end
end

module Matching
  class DoubleSubmitError   < StandardError; end
  class InvalidOrderError   < StandardError; end
  class NotEnoughVolume     < StandardError; end
  class ExceedSumLimit      < StandardError; end
  class TradeExecutionError < StandardError; end
end