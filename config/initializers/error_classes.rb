class AccountError < RuntimeError; end
class Account::LockedError < AccountError; end
class Account::BalanceError < AccountError; end

class OrderError < RuntimeError; end

module OrderBookError
  class NoTop < OrderError; end
  class TooShallow < OrderError; end
  class VolumeTooLarge < OrderError; end
end

module Matching
  class DoubleSubmitError   < StandardError; end
  class InvalidOrderError   < StandardError; end
  class NotEnoughVolume     < StandardError; end
  class ExceedSumLimit      < StandardError; end
  class TradeExecutionError < StandardError; end
end