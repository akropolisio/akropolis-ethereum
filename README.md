

# Akropolis Protocol Implementation

![Akropolis](banner.png?raw=true)

 
## User Journeys


### Functionality: Pension Fund Creation
### User Type: Sponsor
  1. Create a Pension Fund
  2. Complete descriptive fields, set lockup and fees
  3. Leave manager and directors addresses blank
  4. Automatically assigned to the Sponsor
  5. Fee requirements 
### Functionality: Initial Asset Allocation
### User Type: Fund Manager

  1. Setup a transfer
    1. View Director approved investible tokens
    2. Select quantity, address, transfer in, approve
  2. View Fund detail
    1. Change should be reflected
    
### Functionality: Join a Pension Fund & Setup Recurring Contributions
### User Type: Beneficiary
  1. Switch windows to the Manager screen
    1. View join request
    2. Accept join request
  2. View fund detail (should be approved)
  3. Setup a recurring contribution
  4. View contributions and history

## Functionality by User Type 

### Beneficiary

- View available funds & apply to join as an individual
  - Fund detail & composition
  - Apply to join
- View funds invested in
- Make a contribution (one time or recurring)
  - Must be a member
- View contribution history

### Fund Manager

- Create a digital Pension Fund 
  - Name, symbol, risk, description
  - Lockup, Management Fee
  - Fund Manager & BOD Assignment
  - Contract deployment
- Move tokens in/out of Pension Fund
  - Governed by BOD approved investible tokens
- Fund Manager approval/rejection of individual join request

### Sponsor

- Create a digital fund (as defined above)

### Board of Directors (temporary governance measure)

- Initiate a motion
  - Set/change manager
    - Only motion that is currently supported
- Voting on Motions

# Near-Term Roadmap
- [ ]  Extended functionality of the Smart contract factory (edited)
- [ ]  implementation of the upgradeable smart contract architecture
- [ ]  UI/UX buildout on ReactJS
- [ ]  Oracle interaction protocol
- [ ]  Kovan Testnet
- [ ]  Public release Alpha

# Support
Join our support server at https://discord.gg/GZWaZCP for the latest news and information!

# License
Akropolis-Ethereum is released under the MIT License.
