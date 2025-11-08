# 🚛 Clarity-Based Fleet Maintenance Ledger

A blockchain-powered fleet maintenance tracking system built on Stacks that provides immutable records for audit trails and resale value preservation.

## 🎯 Overview

This smart contract enables fleet managers to:
- 📝 Register and manage vehicle fleets
- 🔧 Log maintenance records immutably
- 📊 Track mileage and service history
- 💰 Estimate vehicle values based on maintenance
- 🛡️ Maintain audit trails for compliance

## 🚀 Features

### Vehicle Management
- ✅ Register vehicles with make, model, year, VIN
- 📈 Track current mileage
- ⚡ Activate/deactivate vehicles
- 🏷️ Unique vehicle identification

### Maintenance Tracking
- 🔧 Log detailed maintenance records
- 💵 Track service costs
- 👨‍🔧 Record technician information
- 🗓️ Schedule future maintenance
- 🔩 Track parts replaced

### Fleet Operations
- 👥 Authorize fleet managers
- 🏢 Manage multiple fleets
- 📋 Comprehensive audit trails
- 💡 Value estimation algorithms

## 📋 Contract Functions

### Setup Functions
```clarity
(register-fleet-manager principal fleet-name)
```
Authorizes a principal as a fleet manager (owner only).

### Vehicle Functions
```clarity
(register-vehicle vehicle-id make model year vin initial-mileage)
```
Registers a new vehicle in the fleet.

```clarity
(update-mileage vehicle-id new-mileage)
```
Updates vehicle mileage (must be higher than current).

```clarity
(deactivate-vehicle vehicle-id)
```
Marks a vehicle as inactive.

### Maintenance Functions
```clarity
(log-maintenance vehicle-id type description cost mileage technician next-due parts)
```
Creates an immutable maintenance record.

### Read-Only Functions
```clarity
(get-vehicle vehicle-id)
(get-maintenance-record record-id)
(get-vehicle-value-estimate vehicle-id)
(get-total-maintenance-cost vehicle-id)
```

## 🛠️ Usage Instructions

### 1. Deploy Contract
```bash
clarinet deploy
```

### 2. Register Fleet Manager
```clarity
(contract-call? .fleet-maintenance register-fleet-manager 'SP1234...ABCD "City Transport Fleet")
```

### 3. Register Vehicle
```clarity
(contract-call? .fleet-maintenance register-vehicle 
  "TRUCK001" 
  "Ford" 
  "F-150" 
  u2023 
  "1FTFW1ET5NFC12345" 
  u25000)
```

### 4. Log Maintenance
```clarity
(contract-call? .fleet-maintenance log-maintenance
  "TRUCK001"
  "Oil Change"
  "Routine oil and filter change"
  u75
  u25500
  "John Mechanic"
  u28000
  "Oil filter, engine oil")
```

### 5. Query Data
```clarity
(contract-call? .fleet-maintenance get-vehicle "TRUCK001")
(contract-call? .fleet-maintenance get-vehicle-value-estimate "TRUCK001")
```

## 🔐 Security Features

- **Authorization**: Only fleet managers can register vehicles and log maintenance
- **Validation**: Mileage must always increase, costs must be positive
- **Immutability**: All maintenance records are permanent and tamper-proof
- **Access Control**: Vehicle owners and authorized fleet managers can update data

## 📊 Data Structures

### Vehicle Record
- Vehicle ID, Make, Model, Year, VIN
- Current mileage and registration block
- Owner and active status

### Maintenance Record
- Vehicle association and service details
- Cost, mileage, and service date
- Technician info and parts replaced
- Next service due date

## 💼 Business Benefits

- 📈 **Resale Value**: Complete maintenance history increases vehicle value
- 🛡️ **Audit Compliance**: Immutable records for regulatory requirements
- 📊 **Analytics**: Track maintenance patterns and costs
- 🔍 **Transparency**: Buyers can verify maintenance history
- ⚡ **Efficiency**: Automated record keeping and scheduling

## 🧪 Testing

```bash
clarinet test
```

## 📄 License

MIT License - See LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

---
Built with ❤️ on Stacks blockchain
