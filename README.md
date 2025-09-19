# Scholarix - Exam Lottery Scholarships 🎓

A blockchain-based scholarship distribution system that uses randomized smart contract funding to reward academic excellence through transparent lottery mechanisms.

## Overview

Scholarix revolutionizes educational funding by combining academic performance verification with fair lottery distribution. Students who meet minimum exam requirements enter a decentralized lottery system where scholarships are distributed transparently and randomly, ensuring equal opportunity for deserving candidates.

## Features

### 🎯 Exam-Based Qualification
- Minimum score requirements for scholarship eligibility
- Multiple exam subjects and grading criteria
- Academic performance verification system
- Grade threshold management

### 🎲 Randomized Distribution
- Cryptographically secure random selection
- Fair lottery mechanism using blockchain randomness
- Multiple scholarship tiers and amounts
- Transparent selection process

### 💰 Smart Contract Funding
- Automated scholarship distribution
- STX-based funding pool management
- Multi-sponsor contribution system
- Transparent fund allocation

### 📊 Performance Tracking
- Student academic records
- Scholarship award history
- Sponsor contribution tracking
- System analytics and reporting

## Smart Contracts

### 1. Academic Registry Contract (`academic-registry.clar`)
Manages student academic records and exam scores:
- Student registration and verification
- Exam score submission and validation
- Grade requirements configuration
- Academic performance tracking

### 2. Scholarship Lottery Contract (`scholarship-lottery.clar`)
Handles the randomized scholarship distribution:
- Lottery pool management
- Random selection algorithms
- Scholarship tier configuration
- Winner selection and payout

## Technology Stack

- **Blockchain**: Stacks (STX)
- **Smart Contract Language**: Clarity
- **Development Framework**: Clarinet
- **Testing**: Vitest
- **Randomization**: Block-based entropy

## Getting Started

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet) installed
- [Node.js](https://nodejs.org/) v16+
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Scholarix
```

2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## Usage

### For Students

1. **Register**: Submit academic credentials and personal information
2. **Take Exams**: Complete required examinations with minimum scores
3. **Enter Lottery**: Eligible students automatically enter the scholarship pool
4. **Receive Awards**: Winners receive automatic STX transfers

### For Educational Institutions

1. **Student Verification**: Validate student academic records
2. **Exam Administration**: Submit verified exam scores to the blockchain
3. **Grade Management**: Set minimum requirements for scholarship eligibility
4. **Performance Tracking**: Monitor student academic progress

### For Sponsors

1. **Fund Contribution**: Add STX to the scholarship funding pool
2. **Sponsor Tiers**: Choose scholarship amounts and quantities
3. **Impact Tracking**: Monitor scholarship distribution and student outcomes
4. **Tax Benefits**: Receive transparent donation receipts

### For System Administrators

1. **Lottery Configuration**: Set randomization parameters and timing
2. **Prize Management**: Configure scholarship tiers and amounts
3. **System Monitoring**: Oversee lottery draws and fund distribution
4. **Compliance**: Ensure regulatory compliance and fair practices

## How It Works

### Academic Qualification Process
1. Students register with verified academic credentials
2. Minimum exam scores are required across multiple subjects
3. Only qualified students enter the scholarship lottery pool
4. Academic records are permanently stored on blockchain

### Lottery Selection Process
1. Eligible students are automatically entered into lottery pools
2. Random selection uses block hash entropy for fairness
3. Multiple scholarship tiers offer different award amounts
4. Winners are selected and funds distributed automatically

### Funding and Distribution
1. Sponsors contribute STX to various scholarship pools
2. Funds are held securely in smart contracts
3. Automatic distribution occurs when winners are selected
4. Complete transparency through blockchain records

## Security Features

- **Academic Integrity**: Verified exam scores and grade authentication
- **Fair Randomization**: Cryptographically secure lottery selection
- **Fund Security**: Multi-signature and timelock protections
- **Transparent Process**: All operations recorded on blockchain
- **Anti-Fraud**: Student verification and duplicate prevention

## Benefits

### For Students
- **Merit-Based**: Rewards academic achievement
- **Equal Opportunity**: Fair lottery system for qualified students
- **Transparent Process**: Clear selection criteria and results
- **Immediate Rewards**: Automatic scholarship distribution

### For Institutions
- **Academic Incentives**: Motivates student performance
- **Transparent Records**: Immutable academic achievement records
- **Reduced Administration**: Automated scholarship management
- **Performance Analytics**: Detailed student progress tracking

### for Society
- **Educational Investment**: Rewards academic excellence
- **Transparent Funding**: Clear scholarship distribution
- **Social Mobility**: Equal opportunity for deserving students
- **Innovation**: Blockchain-powered education financing

## Scholarship Tiers

- **Bronze**: Basic scholarship for qualifying students
- **Silver**: Enhanced awards for high performers
- **Gold**: Premium scholarships for exceptional achievements
- **Platinum**: Top-tier awards for outstanding academic excellence

## Future Enhancements

- **Multi-Institution**: Support for multiple schools and universities
- **Skill-Based Lotteries**: Specialized scholarships for different fields
- **Alumni Networks**: Graduate sponsorship and mentoring programs
- **International Exchange**: Cross-border scholarship opportunities
- **Career Tracking**: Post-graduation success monitoring

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For questions or support, please open an issue in the GitHub repository.

---

**🎓 Empowering education through fair, transparent, and merit-based scholarship distribution.**
