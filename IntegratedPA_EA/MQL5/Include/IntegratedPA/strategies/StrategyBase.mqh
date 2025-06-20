#ifndef INTEGRATEDPA_STRATEGYBASE_MQH
#define INTEGRATEDPA_STRATEGYBASE_MQH
#include "../Defs.mqh"
#include "../Utils.mqh"

class IStrategy
{
public:
    virtual ~IStrategy() {}
    virtual string Name() const = 0;
    virtual bool Identify(const string symbol, ENUM_TIMEFRAMES tf) = 0;
    virtual Signal GenerateSignal(const string symbol, ENUM_TIMEFRAMES tf) = 0;
};

#endif // INTEGRATEDPA_STRATEGYBASE_MQH
