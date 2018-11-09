

# Akropolis Protocol Implementation

![Akropolis](https://bitcoinvietnamnews.com/wp-content/uploads/2018/08/akropolis-coin.jpg)


# MVP User Journeys
 

## Journeys


1. Fund Creation (Role: Sponsor)
  1. Create Fund
  2. Complete descriptive fields and set lockup/fee
  3. Leave manager and directors addresses blank
    1. Automatically assigned to the sponsor
  4. Fee requirements 
    1. Will have necessary fee balances ahead of running the demo. This will ensure we are not wasting time waiting for transactions to be completed


1. Initial Asset Allocation (Role: FM)
  1. Setup a transfer
    1. View director approved investible tokens
    2. Select quantity, address, transfer in, approve
  2. View Fund detail
    1. Change should be reflected
2. Join a Fund & Setup Recurring Contributions (Role: Individual)
  1. Switch windows to the Manager screen
    1. View join request
    2. Accept join request
  2. View fund detail (should be approved)
  3. Setup a recurring contribution
  4. View contributions and history
## Functionality (by Role) 

Individual

- View available funds & apply to join as an individual
  - Fund detail & composition
  - Apply to join
- View funds invested in
- Make a contribution (one time or recurring)
  - Must be a member
- View contribution history

Fund Manager

- Create a digital fund
  - Name, symbol, risk, description
  - Lockup, Management Fee
  - Manger & BOD assignment
  - Deploy contract
- Move tokens in/out of fund
  - Governed by BOD approved investible tokens
- Fund Manager approval/rejection of individual join request

Sponsor/Originator 

- Create a digital fund (as defined above)

Board of Directors

- Initiate a motion
  - set/change manager
    - Only motion that is currently supported
- Voting on Motions


# Support
Join our support server at https://discord.gg/GZWaZCP for the latest news and information!


# License
Akropolis-Ethereum is released under the MIT License.
