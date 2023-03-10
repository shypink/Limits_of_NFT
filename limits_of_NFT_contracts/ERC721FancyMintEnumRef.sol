// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.7.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./ERC721FancyMintRef.sol";

// import "OpenZeppelin/openzeppelin-contracts@4.7.0/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// import "OpenZeppelin/openzeppelin-contracts@4.7.0/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts@4.7.0/token/ERC721/extensions/IERC721Enumerable.sol";
/**
 * @dev This implements an optional extension of {ERC721FancyMint} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */

/** WARNING!
 * @dev this token does NOT support minting and burning
 */

contract ERC721FancyMintEnum is ERC721FancyMint, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    /**
     * @dev this token does not need _allTokens & _allTokensIndex they both handeled virtually
     */

    /**
     * @dev this part handle _preOwner tokens to index and tokens index to tokens
     */
    //preOwner _indexHandelr index - >tid
    mapping(uint256 => uint256) private _preOwnerIndexHandler;
    // preOwner _tokenHandler tid -> index
    mapping(uint256 => uint256) private _preOwnerTokenHandler;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        address preOwner_
    ) ERC721FancyMint(name_, symbol_, maxSupply_, preOwner_) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721FancyMint)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**@dev my proposal
     * @param  _index  get it and return tokenId for preOwner
     *
     * since we add 1 in to avoid confusion with defual value of the mapping we  subtract 1 to get tokenIndex
     * if token hasn't been transferd from preOwner the _preOwnerIndexHandler is 0 (defualt value) so we use virtual Indexing to create a value
     */

    function preIndex(uint256 _index) internal view returns (uint256) {
        uint256 virtual_index = _preOwnerIndexHandler[_index];
        if (virtual_index == 0) {
            return _index; //tokenId
        } else {
            return virtual_index - 1; //tokenId
        }
    }

    /**@dev my proposal
     * @param  _tokenId  get it and return tokenIndex for preOwner
     *
     * since we add 1 in to avoid confusion with defual value of the mapping we  subtract 1 to get tokenId
     *if token hasn't been transferd from preOwner the _preOwnerTokenHandler is 0 (defualt value) so we use virtual Indexing to create a value
     */

    function preToken(uint256 _tokenId) internal view returns (uint256) {
        uint256 virtual_token = _preOwnerTokenHandler[_tokenId];
        if (virtual_token == 0) {
            return _tokenId; //index
        } else {
            return virtual_token - 1; //index
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // if preowner
        address _preOwner = ERC721FancyMint.preOwner();

        require(
            index < ERC721FancyMint.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        if (_preOwner == owner) {
            return preIndex(index);
        } else {
            return _ownedTokens[owner][index];
        }
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ERC721FancyMint.maxSupply();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    /**
     * @dev handling tokens index virtualy
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721FancyMintEnum.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return index;
    }

    /**
     *This Token does NOT includes mintingand burning.
     *
     * @dev Hook that is called before any token transfer. This -- NOT --includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, it reverts it has no minting function
     * - When `to` is zero, ``from``'s it reverts it has no burn function
     * - `from` and 'to' cannot be the zero address at the same time.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    /** @dev it's my proposal
     save me */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        address _preOwner = ERC721FancyMint.preOwner();

        if (from == address(0)) {
            //does not support minting
            revert("fromm == zero, does not support minting");
        } else if (from != to) {
            if (from == _preOwner) {
                _removeTokenFromPreOwner(tokenId);
            } else {
                _removeTokenFromOwnerEnumeration(from, tokenId);
            }
        }
        if (to == address(0)) {
            //does not support burning
            revert("to == zero, does not support burning");
        } else if (to != from) {
            if (to == _preOwner) {
                _addTokenToPreOwner(tokenId);
            } else {
                _addTokenToOwnerEnumeration(to, tokenId);
            }
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721FancyMint.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**@dev me
     * it's like _addTokenToOwnerEnumeration function but for the _preOwner.
     */
    function _addTokenToPreOwner(uint256 tokenId) private {
        address _preOwner = ERC721FancyMint.preOwner();
        uint256 length = ERC721FancyMint.balanceOf(_preOwner);
        // add 1 to tokenId to avoid confusion with default value of _preOwnerIndexHandler mapping that is 0
        _preOwnerIndexHandler[length] = tokenId + 1;
        // add 1 to length(that is used for Index) to avoid confusion with default value of _preOwnerTokenHandler mapping that is 0
        _preOwnerTokenHandler[tokenId] = length + 1;
    }

    /**@dev my proposal
    since before _beforeTokenTransfer revert if from = address(0) ,and this token  has no minting function, _addTokenToAllTokensEnumeration function has been removed
     */

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721FancyMint.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**@dev me
     * it's like _removeTokenFromOwnerEnumeration function but for the _preOwner.
     */
    function _removeTokenFromPreOwner(uint256 tokenId) internal {
        address _preOwner = ERC721FancyMint.preOwner();
        uint256 lastTokenIndex = ERC721FancyMint.balanceOf(_preOwner) - 1;
        uint256 tokenIndex = preToken(tokenId);
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = preIndex(lastTokenIndex);
            // Move the last token to the slot of the to delete token ,and add 1 to avoid confusion with defualt  value of _preOwnerIndexHandler mapping  that is 0
            _preOwnerIndexHandler[tokenIndex] = lastTokenId + 1;
            // Update the moved token's index and add 1 to avoid confusion with defualt value of _preOwnerTokenHandler mapping that is 0
            _preOwnerTokenHandler[lastTokenId] = tokenIndex + 1;
        }

        // This also deletes the contents at the last position of the array
        delete _preOwnerIndexHandler[lastTokenIndex];
        delete _preOwnerTokenHandler[tokenId];
    }

    /**@dev my proposal
     * since before _beforeTokenTransfer revert if to = address(0) ,and this token is has no burn function, _removeTokenFromAllTokensEnumeration function has been removed
     */
}
