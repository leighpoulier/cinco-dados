module CincoDados

    class CincoDadosError < RuntimeError
    end

    class ConfigurationError < CincoDadosError
    end

    class GameError < CincoDadosError
    end
    class DadosError < GameError
    end

    class ScoreError < GameError
    end
    class ScoreCategoryError < ScoreError
    end

    class RuleError < ScoreError
    end
end