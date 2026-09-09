export function createInMemoryLinkRepository() {
  const links = new Map();

  return {
    async putIfAbsent(link) {
      if (links.has(link.shortCode)) {
        return false;
      }

      links.set(link.shortCode, { ...link });
      return true;
    },

    async getByShortCode(shortCode) {
      const link = links.get(shortCode);
      return link ? { ...link } : undefined;
    },

    async deleteIfOwned(shortCode, ownerSub) {
      const link = links.get(shortCode);
      if (!link) {
        return 'not_found';
      }
      if (link.ownerSub !== ownerSub) {
        return 'not_owned';
      }

      links.delete(shortCode);
      return 'deleted';
    }
  };
}
