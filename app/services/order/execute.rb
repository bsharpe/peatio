class Order
  class Execute
    include Interactor
    include Interactor::Contracts

    expects do
      required(:order).filled
    end

    def call
    end
  end
end
