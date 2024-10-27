trigger OrderValidationTrigger on Order (before insert, before update) {
    OrderValidationHandler.validateOrders(Trigger.new);
}
