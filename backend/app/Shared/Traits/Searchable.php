<?php

namespace App\Shared\Traits;

use Illuminate\Database\Eloquent\Builder;

trait Searchable
{
    /**
     * @param  array<int, string>  $columns
     */
    public function scopeSearch(Builder $query, ?string $term, array $columns = []): Builder
    {
        if (blank($term) || $columns === []) {
            return $query;
        }

        return $query->where(function (Builder $builder) use ($term, $columns): void {
            foreach ($columns as $index => $column) {
                $method = $index === 0 ? 'where' : 'orWhere';
                $builder->{$method}($column, 'like', "%{$term}%");
            }
        });
    }
}