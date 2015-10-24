module Houston
  module Feedback
    class CustomersController < ApplicationController

      def create
        customer = Customer.create(
          name: params[:name],
          attributions: [params[:attribution]])
        if customer.persisted?
          head :ok
        else
          render json: customer.errors, status: :unprocessable_entity
        end
      end

      def add_attribution
        customer = Customer.find params[:id]
        if customer.add_attribution params[:attribution]
          head :ok
        else
          render json: customer.errors, status: :unprocessable_entity
        end
      end

    end
  end
end
