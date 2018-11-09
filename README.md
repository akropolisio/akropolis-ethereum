

# Akropolis Protocol Implementation

![Akropolis](banner.png?raw=true)

The goal of the MVP is to demonstrate how the core components and network participants interact. Below are a few defined journeys that build on one another to showcase this interaction as a progression of events.
 
# User Journeys


### Functionality "Pension Fund Creation" by User Type "Sponsor"
  - Create a Pension Fund
  - Complete descriptive fields, set lockup and fees
  - Leave Manager and Directors addresses blank
    - Automatically assigned to the Sponsor
  - Fee requirements 
    - Will have necessary fee balances ahead of running the demo. This will ensure we are not wasting time waiting for transactions to be completed
  - Deploy board and fund
  - Stake AKT
  - Select “View Funds” menu item
  - Select newly created fund and view fund detail 


### Functionality "Initial Allocation" by User Type "Manager"
  - Setup a transfer
    - View Director approved investible tokens
    - Select quantity, address, transfer in, approve
  - View Fund detail
    - Change should be reflected
    
### Functionality "Join a Pension Fund & Setup Recurring Contributions" by User Type "Beneficiary"
  - Switch windows to the Manager screen
    - View join request
    - Accept join request
  - View fund detail (should be approved)
  - Setup a recurring contribution
  - View contributions and history

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
