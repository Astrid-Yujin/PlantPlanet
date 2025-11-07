//
//  Species.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 11/6/25.
//

import Foundation
import SwiftData

@Model
class Species {
    var id = UUID()
    var name: String
    var group: String
    var isStarred: Bool
    var isUserDefined: Bool // 标识是否为用户自定义的品种
    var createdAt: Date
    
    init(name: String, group: String = "Other", isStarred: Bool = false, isUserDefined: Bool = false) {
        self.name = name
        self.group = group
        self.isStarred = isStarred
        self.isUserDefined = isUserDefined
        self.createdAt = Date()
    }
    
    func isEqual(to other: Species) -> Bool {
        return self.name.lowercased() == other.name.lowercased()
    }
}


class SpeciesManager {
    
    /// 创建默认的植物品种
    static func createDefaultSpecies(context: ModelContext) {
        let defaultSpeciesData: [(name: String, group: SpeciesGroup)] = [
            // 常见花卉
            ("Rose", .flowers), ("Tulip", .flowers), ("Sunflower", .flowers), ("Daisy", .flowers),
            ("Lily", .flowers), ("Orchid", .flowers), ("Peony", .flowers), ("Chrysanthemum", .flowers),
            ("Carnation", .flowers), ("Iris", .flowers), ("Daffodil", .flowers), ("Hyacinth", .flowers),
            ("Marigold", .flowers), ("Petunia", .flowers), ("Pansy", .flowers),
            
            // 常见观叶植物
            ("Pothos", .foliage), ("Snake Plant", .foliage), ("Monstera", .foliage), ("Philodendron", .foliage),
            ("Fiddle Leaf Fig", .foliage), ("Peace Lily", .foliage), ("ZZ Plant", .foliage), ("Spider Plant", .foliage),
            ("Rubber Plant", .foliage), ("Boston Fern", .foliage), ("Aloe Vera", .foliage), ("English Ivy", .foliage),
            
            // 多肉植物
            ("Succulent", .succulents), ("Echeveria", .succulents), ("Jade Plant", .succulents), ("String of Pearls", .succulents),
            ("Haworthia", .succulents), ("Sedum", .succulents), ("Crassula", .succulents), ("Aeonium", .succulents),
            ("Kalanchoe", .succulents), ("Lithops", .succulents),
            
            // 香草植物
            ("Basil", .herbs), ("Mint", .herbs), ("Rosemary", .herbs), ("Thyme", .herbs),
            ("Oregano", .herbs), ("Sage", .herbs), ("Lavender", .herbs), ("Parsley", .herbs),
            
            // 观花灌木
            ("Azalea", .shrubs), ("Rhododendron", .shrubs), ("Hydrangea", .shrubs), ("Camellia", .shrubs),
            ("Gardenia", .shrubs), ("Hibiscus", .shrubs), ("Bougainvillea", .shrubs), ("Jasmine", .shrubs),
            
            // 蔬菜
            ("Tomato", .vegetables), ("Pepper", .vegetables), ("Lettuce", .vegetables), ("Spinach", .vegetables),
            ("Carrot", .vegetables), ("Radish", .vegetables), ("Cucumber", .vegetables), ("Beans", .vegetables),
            
            // 树木
            ("Maple", .trees), ("Oak", .trees), ("Pine", .trees), ("Birch", .trees),
            ("Cherry", .trees), ("Apple", .trees), ("Lemon", .trees), ("Orange", .trees),
            
            // 藤本植物
            ("Morning Glory", .vines), ("Clematis", .vines), ("Wisteria", .vines), ("Grape Vine", .vines),
            ("Passion Fruit", .vines)
        ]
        
        for (speciesName, group) in defaultSpeciesData {
            // 检查是否已存在
            let fetchRequest = FetchDescriptor<Species>(
                predicate: #Predicate<Species> { species in
                    species.name == speciesName
                }
            )
            
            if let existingSpecies = try? context.fetch(fetchRequest), !existingSpecies.isEmpty {
                // 如果品种已存在但没有分组信息，更新分组
                if let existing = existingSpecies.first, existing.group.isEmpty {
                    existing.group = group.rawValue
                }
                continue
            }
            
            let species = Species(name: speciesName, group: group.rawValue)
            context.insert(species)
        }
        
        try? context.save()
    }
    
    /// 添加新品种
    static func addSpecies(_ species: Species, context: ModelContext) {
        context.insert(species)
        try? context.save()
    }
    
    /// 获取排序后的品种列表（星标优先，然后按分组和字母排序）
    static func sortedSpecies(_ allSpecies: [Species]) -> [Species] {
        let sorted = allSpecies.sorted { first, second in
            // 星标的排在前面
            if first.isStarred != second.isStarred {
                return first.isStarred
            }
            // 相同星标状态下按分组排序
            if first.group != second.group {
                return first.group.localizedCaseInsensitiveCompare(second.group) == .orderedAscending
            }
            // 相同分组下按名称字母排序
            return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
        }
        
        return sorted
    }
    
    /// 搜索品种
    static func searchSpecies(_ allSpecies: [Species], searchText: String) -> [Species] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return sortedSpecies(allSpecies)
        }
        
        let filtered = allSpecies.filter { species in
            species.name.localizedCaseInsensitiveContains(searchText)
        }
        
        return sortedSpecies(filtered)
    }
    
    /// 按分组对品种进行分类，并按指定顺序排序分组
    static func speciesGroupedByCategory(_ species: [Species]) -> [String: [Species]] {
        let grouped = Dictionary(grouping: species) { species in
            if species.isUserDefined {
                return SpeciesGroup.custom.rawValue
            }
            return species.group.isEmpty ? SpeciesGroup.other.rawValue : species.group
        }
        
        return grouped
    }
    
    /// 获取排序后的分组名称（星标 > 自定义 > 其他分组）
    static func sortedGroupNames(from groupedSpecies: [String: [Species]], hasStarredSpecies: Bool = false) -> [String] {
        var sortedNames: [String] = []
        
        // 1. 如果有星标品种，先显示星标分组（虚拟分组）
        if hasStarredSpecies {
            sortedNames.append("⭐ Starred")
        }
        
        // 2. 自定义分组
        if groupedSpecies[SpeciesGroup.custom.rawValue] != nil {
            sortedNames.append(SpeciesGroup.custom.rawValue)
        }
        
        // 3. 其他分组（按字母排序）
        let otherGroups = groupedSpecies.keys.filter { groupName in
            groupName != SpeciesGroup.custom.rawValue
        }.sorted { first, second in
            first.localizedCaseInsensitiveCompare(second) == .orderedAscending
        }
        
        sortedNames.append(contentsOf: otherGroups)
        
        return sortedNames
    }
    
    /// 获取最常用的品种（基于使用该品种的植物数量）
    static func getMostUsedSpecies(from plants: [Plant], limit: Int = 10) -> [String] {
        let speciesCount = Dictionary(grouping: plants, by: { $0.species })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
        
        return Array(speciesCount)
    }
}


// MARK: - Species Groups

enum SpeciesGroup: String, CaseIterable {
    case custom = "Custom"
    case flowers = "Flowers"
    case foliage = "Foliage Plants"
    case succulents = "Succulents"
    case herbs = "Herbs"
    case shrubs = "Flowering Shrubs"
    case vegetables = "Vegetables"
    case trees = "Trees"
    case vines = "Vines"
    case other = "Other"
    
    var localizedName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .custom:
            return "🏷️"
        case .flowers:
            return "🌸"
        case .foliage:
            return "🌿"
        case .succulents:
            return "🌵"
        case .herbs:
            return "🌱"
        case .shrubs:
            return "🌺"
        case .vegetables:
            return "🥬"
        case .trees:
            return "🌳"
        case .vines:
            return "🍇"
        case .other:
            return "🌾"
        }
    }
    
    static func fromString(_ string: String) -> SpeciesGroup {
        return SpeciesGroup(rawValue: string) ?? .other
    }
}
