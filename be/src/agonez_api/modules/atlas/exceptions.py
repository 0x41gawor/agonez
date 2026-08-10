class AtlasEntityNotFoundError(LookupError):
    def __init__(self, entity: str, slug: str) -> None:
        self.entity = entity
        self.slug = slug
        super().__init__(f"{entity} not found")
