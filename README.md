

# Akropolis Protocol Implementation

![Akropolis](https://pbs.twimg.com/profile_banners/935139646224371712/1539031201/1500x500)


# User Journeys
 

## Journeys


### Fund Creation (Role: Sponsor)
  1. Create Fund
  2. Complete descriptive fields and set lockup/fee
  3. Leave manager and directors addresses blank
    1. Automatically assigned to the sponsor
  4. Fee requirements 
    1. Will have necessary fee balances ahead of running the demo. This will ensure we are not wasting time waiting for transactions to be completed


### Initial Asset Allocation (Role: FM)
  1. Setup a transfer
    1. View director approved investible tokens
    2. Select quantity, address, transfer in, approve
  2. View Fund detail
    1. Change should be reflected
### Join a Fund & Setup Recurring Contributions (Role: Individual)
  1. Switch windows to the Manager screen
    1. View join request
    2. Accept join request
  2. View fund detail (should be approved)
  3. Setup a recurring contribution
  4. View contributions and history
## Functionality (by Role) 

### Individual

 1. View available funds & apply to join as an individual
   1. Fund detail & composition
   2. Apply to join
 2. View funds invested in
 3. Make a contribution (one time or recurring)
   1. Must be a member
 4. View contribution history

### Fund Manager

 1. Create a digital fund
   1. Name, symbol, risk, description
   2. Lockup, Management Fee
   3. Manger & BOD assignment
   4. Deploy contract
2. Move tokens in/out of fund
  1. Governed by BOD approved investible tokens
  2. Fund Manager approval/rejection of individual join request

### Sponsor/Originator 

1. Create a digital fund (as defined above)

### Board of Directors

1. Initiate a motion
  1. set/change manager (Only motion that is currently supported)
  2. Voting on Motions


# TODO
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
