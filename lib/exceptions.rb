module CincoDados

    class CincoDadosError < RuntimeError
    end
    class DadosError < CincoDadosError
    end

    class ScoreError < CincoDadosError
    end
    class CategoryError < ScoreError
    end

    class RuleError < ScoreError
    end
end